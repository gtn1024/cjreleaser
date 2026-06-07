package cjreleaser

import std.collection.*

public class ReleaseConfig {
    public var dryRun: Bool = false
    public var bundleOnly: Bool = false
    public var verbose: Bool = false
    public var skipTest: Bool = false
    public var skipLint: Bool = false
    public var rootPath: String = ""
    public var onlyPackages: HashSet<String> = HashSet<String>()
    public var excludePackages: HashSet<String> = HashSet<String>()
}

public class ReleaseContext {
    var rootDir: String
    var config: ReleaseConfig
    public var ws: ?WorkspaceInfo = None
    public var order: Array<String> = Array<String>()
    public let report: CheckReport = CheckReport()

    public init(rootDir: String, config: ReleaseConfig) {
        this.rootDir = rootDir
        this.config = config
    }

    public func discover(): Bool {
        let result = discoverWorkspace(rootDir)
        if (let Some(w) <- result) {
            ws = w
            return true
        }
        eprintln("Error: failed to discover workspace")
        return false
    }

    public func precheck(): Bool {
        if (let Some(w) <- ws) {
            let graph = DepGraph(w.packages)
            if (!graph.build()) {
                return false
            }

            let sorted = graph.topologicalSort()
            if (let Some(s) <- sorted) {
                order = s
            } else {
                return false
            }

            let results = runPrecheck(w, order, config)
            report.results = results
            report.order = filterPackages(order, config)
            report.isWorkspace = w.isWorkspace

            return !report.hasErrors()
        }
        return false
    }

    public func bundle(): Bool {
        if (let Some(w) <- ws) {
            return runBundle(w, order, config)
        }
        return false
    }

    public func publish(): Bool {
        if (let Some(w) <- ws) {
            return runPublish(w, order, config)
        }
        return false
    }
}
