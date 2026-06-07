package cjreleaser

import cjxe.{App}
import cjxe.args.{Arg, ArgMatches}
import cjreleaser.toml.*
import std.env.*
import std.fs.*

main(): Int64 {
    let matches = App("cjreleaser")
        .version("0.1.0")
        .about("Automated release tool for Cangjie monorepo packages")
        .arg(Arg(name: "dry-run", short: r"n", long: "dry-run")
            .setHelp("Run checks without publishing"))
        .arg(Arg(name: "bundle-only", long: "bundle-only")
            .setHelp("Transform and bundle without publishing"))
        .arg(Arg(name: "verbose", short: r"v", long: "verbose")
            .setHelp("Enable verbose output"))
        .arg(Arg(name: "skip-test", long: "skip-test")
            .setHelp("Skip running cjpm test"))
        .arg(Arg(name: "skip-lint", long: "skip-lint")
            .setHelp("Skip running cjlint"))
        .arg(Arg(name: "root", short: r"r", long: "root")
            .setTakesValue(true)
            .setHelp("Specify project root directory"))
        .arg(Arg(name: "only", long: "only")
            .setTakesValue(true)
            .setHelp("Only publish specified packages (comma-separated)"))
        .arg(Arg(name: "exclude", long: "exclude")
            .setTakesValue(true)
            .setHelp("Exclude specified packages (comma-separated)"))
        .getMatchesOrExit()

    let config = parseConfig(matches)

    let rootDir = if (config.rootPath.isEmpty()) {
        getWorkingDirectory().toString()
    } else {
        config.rootPath
    }

    let ctx = ReleaseContext(rootDir, config)

    if (!ctx.discover()) {
        return 1
    }

    if (!ctx.precheck()) {
        ctx.report.printReport()
        return 1
    }

    ctx.report.printReport()

    if (config.dryRun) {
        println("\n[dry-run] No changes made.")
        return 0
    }

    if (config.bundleOnly) {
        if (!ctx.bundle()) {
            return 1
        }
        println("\n[bundle-only] Bundles ready. Skipping publish.")
        return 0
    }

    if (!ctx.publish()) {
        return 1
    }

    return 0
}

func parseConfig(matches: ArgMatches): ReleaseConfig {
    let config = ReleaseConfig()

    let rootDir = if (let Some(root) <- matches.valueOf("root")) {
        root
    } else {
        getWorkingDirectory().toString()
    }
    config.rootPath = rootDir

    loadConfigFile(rootDir, config)

    if (matches.isPresent("dry-run")) {
        config.dryRun = true
    }
    if (matches.isPresent("bundle-only")) {
        config.bundleOnly = true
    }
    if (matches.isPresent("verbose")) {
        config.verbose = true
    }
    if (matches.isPresent("skip-test")) {
        config.skipTest = true
    }
    if (matches.isPresent("skip-lint")) {
        config.skipLint = true
    }

    if (let Some(onlyStr) <- matches.valueOf("only")) {
        config.onlyPackages.clear()
        for (name in onlyStr.split(",")) {
            config.onlyPackages.add(name.trimAscii())
        }
    }

    if (let Some(excludeStr) <- matches.valueOf("exclude")) {
        config.excludePackages.clear()
        for (name in excludeStr.split(",")) {
            config.excludePackages.add(name.trimAscii())
        }
    }

    return config
}

func loadConfigFile(rootDir: String, config: ReleaseConfig): Unit {
    let configPath = Path(rootDir).join("cjreleaser.toml").toString()
    if (!exists(configPath)) {
        return
    }

    try {
        let content = String.fromUtf8(File.readFrom(configPath))
        let p = parse(content)
        let root = p.mapping

        if (let Some(releaseVal) <- root.get("release")) {
            match (releaseVal) {
                case o: TomlObject =>
                    if (let Some(v) <- o.get("skip-test")) {
                        match (v) {
                            case b: TomlBoolean => config.skipTest = b.value
                            case _ => ()
                        }
                    }
                    if (let Some(v) <- o.get("skip-lint")) {
                        match (v) {
                            case b: TomlBoolean => config.skipLint = b.value
                            case _ => ()
                        }
                    }
                    if (let Some(v) <- o.get("include")) {
                        match (v) {
                            case arr: TomlArray =>
                                config.onlyPackages.clear()
                                for (i in 0..arr.size) {
                                    match (arr[i]) {
                                        case s: TomlString => config.onlyPackages.add(s.value)
                                        case _ => ()
                                    }
                                }
                            case _ => ()
                        }
                    }
                    if (let Some(v) <- o.get("exclude")) {
                        match (v) {
                            case arr: TomlArray =>
                                config.excludePackages.clear()
                                for (i in 0..arr.size) {
                                    match (arr[i]) {
                                        case s: TomlString => config.excludePackages.add(s.value)
                                        case _ => ()
                                    }
                                }
                            case _ => ()
                        }
                    }
                case _ => ()
            }
        }
    } catch (e: Exception) {
        eprintln("Warning: failed to parse cjreleaser.toml: ${e.message}")
    }
}
