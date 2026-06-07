package cjreleaser

import std.collection.*
import std.fs.*

public func transformForPublish(pkg: PackageInfo, ws: WorkspaceInfo, stagingDir: String): Bool {
    if (!copyPackageToStaging(pkg, stagingDir)) {
        return false
    }

    let tomlPath = Path(stagingDir).join("cjpm.toml").toString()
    let content = readFileContent(tomlPath) ?? return false

    let transformed = rewritePathDeps(content, pkg, ws)

    try {
        File.writeTo(tomlPath, transformed.toArray())
        return true
    } catch (e: Exception) {
        eprintln("Error: failed to write transformed cjpm.toml: ${e.message}")
        return false
    }
}

func copyPackageToStaging(pkg: PackageInfo, stagingDir: String): Bool {
    try {
        if (exists(stagingDir)) {
            remove(stagingDir, recursive: true)
        }
        Directory.create(stagingDir, recursive: true)
        copy(pkg.dirPath, to: stagingDir, overwrite: true)
        return true
    } catch (e: Exception) {
        eprintln("Error: failed to copy package to staging: ${e.message}")
        return false
    }
}

func rewritePathDeps(content: String, currentPkg: PackageInfo, ws: WorkspaceInfo): String {
    var result = content

    for ((depName, depInfo) in currentPkg.dependencies) {
        if (!depInfo.isPathDep()) {
            continue
        }

        if (let Some(depPkg) <- ws.packages.get(depName)) {
            let depOrg = depPkg.organization
            let depVer = depPkg.version
            let orgPart = if (depOrg.isEmpty()) { "" } else { ", organization = \"${depOrg}\"" }

            let oldPattern = "${depName} = { path = \"${depInfo.path}\""
            let newReplacement = "${depName} = { version = \"${depVer}\"${orgPart}"

            result = result.replace(oldPattern, newReplacement)
        }
    }

    return result
}
