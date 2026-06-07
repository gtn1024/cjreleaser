package cjreleaser

import std.collection.*
import std.process.*
import std.fs.*

public func runBundle(ws: WorkspaceInfo, order: Array<String>, config: ReleaseConfig): Bool {
    let filteredOrder = filterPackages(order, config)
    let stagingBase = Path(ws.rootDir).join(".cjreleaser").toString()

    try {
        if (exists(stagingBase)) {
            remove(stagingBase, recursive: true)
        }
        Directory.create(stagingBase, recursive: true)
    } catch (e: Exception) {
        eprintln("Error: failed to create staging directory '${stagingBase}': ${e.message}")
        return false
    }

    var success = true
    for (name in filteredOrder) {
        if (let Some(pkg) <- ws.packages.get(name)) {
            println("\n[cjreleaser] Bundling ${name}-${pkg.version}...")

            let stagingDir = Path(stagingBase).join("${name}-${pkg.version}").toString()

            if (!transformForPublish(pkg, ws, stagingDir)) {
                eprintln("Error: failed to prepare staging for '${name}'")
                success = false
                break
            }

            if (!runBundleOnly(stagingDir, config)) {
                eprintln("Error: failed to bundle '${name}'")
                success = false
                break
            }

            println("[cjreleaser] ${name}-${pkg.version} bundled successfully → ${stagingDir}")
        }
    }

    if (!success) {
        try {
            remove(stagingBase, recursive: true)
        } catch (_: Exception) {}
    }

    return success
}

func runBundleOnly(dir: String, config: ReleaseConfig): Bool {
    var bundleArgs = ArrayList<String>()
    bundleArgs.add("bundle")
    if (config.skipTest) {
        bundleArgs.add("--skip-test")
    }
    if (config.skipLint) {
        bundleArgs.add("--skip-lint")
    }
    if (config.verbose) {
        bundleArgs.add("--verbose")
    }

    println("[cjreleaser] Running cjpm bundle...")
    let bundleCode = execute("cjpm", bundleArgs.toArray(), workingDirectory: Path(dir))
    if (bundleCode != 0) {
        eprintln("Error: cjpm bundle failed (exit code ${bundleCode})")
        return false
    }

    return true
}

public func runPublish(ws: WorkspaceInfo, order: Array<String>, config: ReleaseConfig): Bool {
    let filteredOrder = filterPackages(order, config)
    let stagingBase = Path(ws.rootDir).join(".cjreleaser").toString()

    try {
        if (exists(stagingBase)) {
            remove(stagingBase, recursive: true)
        }
        Directory.create(stagingBase, recursive: true)
    } catch (e: Exception) {
        eprintln("Error: failed to create staging directory '${stagingBase}': ${e.message}")
        return false
    }

    var success = true
    for (name in filteredOrder) {
        if (let Some(pkg) <- ws.packages.get(name)) {
            println("\n[cjreleaser] Publishing ${name}-${pkg.version}...")

            let stagingDir = Path(stagingBase).join("${name}-${pkg.version}").toString()

            if (!transformForPublish(pkg, ws, stagingDir)) {
                eprintln("Error: failed to prepare staging for '${name}'")
                success = false
                break
            }

            if (!runBundleAndPublish(stagingDir, config)) {
                eprintln("Error: failed to publish '${name}'")
                success = false
                break
            }

            println("[cjreleaser] ${name}-${pkg.version} published successfully")

            if (!waitForPackagePublish(name, pkg.version, pkg.organization, 600, 10)) {
                eprintln("Error: '${name}-${pkg.version}' was published but not yet indexed")
                success = false
                break
            }
        }
    }

    if (config.verbose) {
        println("[cjreleaser] Staging directory: ${stagingBase}")
    } else {
        try {
            remove(stagingBase, recursive: true)
        } catch (_: Exception) {}
    }

    return success
}

func runBundleAndPublish(dir: String, config: ReleaseConfig): Bool {
    println("[cjreleaser] Running cjpm update...")
    let updateCode = execute("cjpm", ["update"], workingDirectory: Path(dir))
    if (updateCode != 0) {
        eprintln("Error: cjpm update failed (exit code ${updateCode})")
        return false
    }

    var bundleArgs = ArrayList<String>()
    bundleArgs.add("bundle")
    if (config.skipTest) {
        bundleArgs.add("--skip-test")
    }
    if (config.skipLint) {
        bundleArgs.add("--skip-lint")
    }
    if (config.verbose) {
        bundleArgs.add("--verbose")
    }

    println("[cjreleaser] Running cjpm bundle...")
    let bundleCode = execute("cjpm", bundleArgs.toArray(), workingDirectory: Path(dir))
    if (bundleCode != 0) {
        eprintln("Error: cjpm bundle failed (exit code ${bundleCode})")
        return false
    }

    var publishArgs = ArrayList<String>()
    publishArgs.add("publish")
    if (config.verbose) {
        publishArgs.add("--verbose")
    }

    println("[cjreleaser] Running cjpm publish...")
    let publishCode = execute("cjpm", publishArgs.toArray(), workingDirectory: Path(dir))
    if (publishCode != 0) {
        eprintln("Error: cjpm publish failed (exit code ${publishCode})")
        return false
    }

    return true
}
