package cjreleaser

import std.collection.*
import std.fs.*

public class CheckResult {
    public var packageName: String = ""
    public var errors: ArrayList<String> = ArrayList<String>()
    public var warnings: ArrayList<String> = ArrayList<String>()
    public var status: String = "ok"

    public func hasErrors(): Bool {
        return errors.size > 0
    }
}

public func runPrecheck(ws: WorkspaceInfo, order: Array<String>, config: ReleaseConfig): ArrayList<CheckResult> {
    let results = ArrayList<CheckResult>()

    let filteredOrder = filterPackages(order, config)
    let plannedSet = HashSet<String>()
    for (name in filteredOrder) {
        plannedSet.add(name)
    }

    for (name in filteredOrder) {
        if (let Some(pkg) <- ws.packages.get(name)) {
            let result = checkPackage(pkg, ws, plannedSet)
            results.add(result)
        }
    }

    return results
}

func filterPackages(order: Array<String>, config: ReleaseConfig): Array<String> {
    let result = ArrayList<String>()

    for (name in order) {
        if (config.onlyPackages.size > 0 && !config.onlyPackages.contains(name)) {
            continue
        }
        if (config.excludePackages.size > 0 && config.excludePackages.contains(name)) {
            continue
        }
        result.add(name)
    }

    return result.toArray()
}

func checkPackage(pkg: PackageInfo, ws: WorkspaceInfo, plannedSet: HashSet<String>): CheckResult {
    let result = CheckResult()
    result.packageName = pkg.name

    checkName(pkg, result)
    checkDescription(pkg, result)
    checkReadme(pkg, result)
    checkOrganization(pkg, result)
    checkDependencies(pkg, ws, plannedSet, result)

    if (result.hasErrors()) {
        result.status = "error"
    } else if (result.warnings.size > 0) {
        result.status = "warn"
    } else {
        result.status = "ok"
    }

    return result
}

func checkName(pkg: PackageInfo, result: CheckResult): Unit {
    if (pkg.name.isEmpty()) {
        result.errors.add("package.name is empty")
        return
    }
    if (pkg.name.size < 3 || pkg.name.size > 64) {
        result.errors.add("package.name '${pkg.name}' length should be in [3, 64], got ${pkg.name.size}")
    }
}

func checkDescription(pkg: PackageInfo, result: CheckResult): Unit {
    if (pkg.description.isEmpty()) {
        result.errors.add("package.description is empty (required for publish)")
    }
}

func checkReadme(pkg: PackageInfo, result: CheckResult): Unit {
    let readmePath = Path(pkg.dirPath).join("README.md").toString()
    let readmeZhPath = Path(pkg.dirPath).join("README_zh.md").toString()
    if (!exists(readmePath) && !exists(readmeZhPath)) {
        result.errors.add("missing README.md or README_zh.md in package root")
    }
}

func checkOrganization(pkg: PackageInfo, result: CheckResult): Unit {
    if (!pkg.organization.isEmpty()) {
        if (pkg.organization.size < 3 || pkg.organization.size > 64) {
            result.errors.add("package.organization '${pkg.organization}' length should be in [3, 64]")
        }
        if (pkg.organization == "default") {
            result.errors.add("package.organization cannot be 'default'")
        }
    }
}

func checkDependencies(pkg: PackageInfo, ws: WorkspaceInfo, plannedSet: HashSet<String>, result: CheckResult): Unit {
    for ((depName, depInfo) in pkg.dependencies) {
        if (depInfo.isPathDep()) {
            if (!plannedSet.contains(depName)) {
                result.warnings.add("dependency '${depName}' is a path dependency not in this release plan; " +
                    "make sure it has been published to central repository")
            }
        } else if (depInfo.isGitDep()) {
            result.errors.add("dependency '${depName}' is a git dependency; " +
                "all dependencies must be central repository format for publish")
        }
    }
}
