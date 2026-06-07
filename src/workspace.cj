package cjreleaser

import cjreleaser.toml.*
import std.collection.*
import std.fs.*

public class PackageInfo {
    public var name: String = ""
    public var version: String = ""
    public var organization: String = ""
    public var description: String = ""
    public var outputType: String = "static"
    public var repository: String = ""
    public var homepage: String = ""
    public var documentation: String = ""
    public var cjcVersion: String = ""
    public var dirPath: String = ""
    public var dependencies: HashMap<String, DepInfo> = HashMap<String, DepInfo>()
}

public class DepInfo {
    public var version: String = ""
    public var path: String = ""
    public var git: String = ""
    public var branch: String = ""
    public var organization: String = ""

    public func isPathDep(): Bool {
        return !path.isEmpty()
    }

    public func isGitDep(): Bool {
        return !git.isEmpty()
    }
}

public class WorkspaceInfo {
    public var rootDir: String = ""
    public var members: ArrayList<String> = ArrayList<String>()
    public var packages: HashMap<String, PackageInfo> = HashMap<String, PackageInfo>()
    public var isWorkspace: Bool = false
}

public func discoverWorkspace(rootDir: String): ?WorkspaceInfo {
    let tomlPath = Path(rootDir).join("cjpm.toml").toString()
    if (!exists(tomlPath)) {
        eprintln("Error: cannot find cjpm.toml in '${rootDir}'")
        return None
    }

    let tomlContent = readFileContent(tomlPath) ?? return None
    let p = parse(tomlContent)
    let root = p.mapping

    let ws = WorkspaceInfo()
    ws.rootDir = rootDir

    if (let Some(wsVal) <- root.get("workspace")) {
        let wsObj = wsVal.asObject()
        ws.isWorkspace = true
        if (let Some(membersVal) <- wsObj.get("members")) {
            let arr = membersVal.asArray()
            for (i in 0..arr.size) {
                match (arr[i]) {
                    case v: TomlString =>
                        if (!v.value.isEmpty()) {
                            ws.members.add(v.value)
                        }
                    case _ => ()
                }
            }
        }

        for (member in ws.members) {
            let memberDir = Path(rootDir).join(member).toString()
            let pkg = parsePackage(memberDir)
            if (let Some(p) <- pkg) {
                ws.packages.add(p.name, p)
            } else {
                return None
            }
        }
    } else {
        ws.isWorkspace = false
        let pkg = parsePackage(rootDir)
        if (let Some(p) <- pkg) {
            ws.packages.add(p.name, p)
        } else {
            return None
        }
    }

    return ws
}

func parsePackage(dirPath: String): ?PackageInfo {
    let tomlPath = Path(dirPath).join("cjpm.toml").toString()
    if (!exists(tomlPath)) {
        eprintln("Error: cannot find cjpm.toml in '${dirPath}'")
        return None
    }

    let content = readFileContent(tomlPath) ?? return None
    let p = parse(content)
    let root = p.mapping

    let pkg = PackageInfo()
    pkg.dirPath = dirPath

    if (let Some(pkgVal) <- root.get("package")) {
        match (pkgVal) {
            case o: TomlObject =>
                pkg.name = getStringValue(o, "name")
                pkg.version = getStringValue(o, "version")
                pkg.description = getStringValue(o, "description")
                pkg.outputType = getStringValue(o, "output-type", default: "static")
                pkg.organization = getStringValue(o, "organization")
                pkg.repository = getStringValue(o, "repository")
                pkg.homepage = getStringValue(o, "homepage")
                pkg.documentation = getStringValue(o, "documentation")
                pkg.cjcVersion = getStringValue(o, "cjc-version")
            case _ => ()
        }
    }

    if (let Some(depsVal) <- root.get("dependencies")) {
        parseDeps(depsVal.asObject(), pkg.dependencies)
    }

    return pkg
}

func getStringValue(obj: TomlObject, key: String, default!: String = ""): String {
    match (obj.get(key)) {
        case Some(v) =>
            match (v) {
                case s: TomlString => return s.value
                case _ => return default
            }
        case _ => return default
    }
}

func parseDeps(obj: TomlObject, deps: HashMap<String, DepInfo>): Unit {
    for ((name, val) in obj.value) {
        match (val) {
            case s: TomlString =>
                let dep = DepInfo()
                dep.version = s.value
                deps.add(name, dep)
            case o: TomlObject =>
                let dep = DepInfo()
                dep.version = getStringValue(o, "version")
                dep.path = getStringValue(o, "path")
                dep.git = getStringValue(o, "git")
                dep.branch = getStringValue(o, "branch")
                dep.organization = getStringValue(o, "organization")
                deps.add(name, dep)
            case _ => ()
        }
    }
}

func readFileContent(path: String): ?String {
    try {
        return String.fromUtf8(File.readFrom(path))
    } catch (e: Exception) {
        eprintln("Error: failed to read '${path}': ${e.message}")
        return None
    }
}
