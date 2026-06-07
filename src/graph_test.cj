package cjreleaser

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*

func makePkg(name: String, deps: Array<(String, String)>): PackageInfo {
    let pkg = PackageInfo()
    pkg.name = name
    pkg.version = "1.0.0"
    for ((depName, depPath) in deps) {
        let dep = DepInfo()
        dep.path = depPath
        pkg.dependencies.add(depName, dep)
    }
    return pkg
}

func buildPackages(pkgs: Array<(String, Array<(String, String)>)>): HashMap<String, PackageInfo> {
    let result = HashMap<String, PackageInfo>()
    for ((name, deps) in pkgs) {
        result.add(name, makePkg(name, deps))
    }
    return result
}

func idxOf(arr: Array<String>, value: String): Int64 {
    for (i in 0..arr.size) {
        if (arr[i] == value) {
            return i
        }
    }
    return -1
}

func unwrapSorted(opt: ?Array<String>): Array<String> {
    match (opt) {
        case Some(arr) => arr
        case None => throw Exception("expected sorted result but got None (cycle?)")
    }
}

@Test
func testTopologicalSortSinglePackage(): Unit {
    let packages = buildPackages([("a", [])])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())
    if (sorted.size != 1) { throw Exception("expected 1") }
    if (sorted[0] != "a") { throw Exception("expected a") }
}

@Test
func testTopologicalSortLinearChain(): Unit {
    let packages = buildPackages([
        ("a", []),
        ("b", [("a", "../a")]),
        ("c", [("b", "../b")])
    ])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())

    if (sorted.size != 3) { throw Exception("expected 3") }
    if (sorted[0] != "a") { throw Exception("expected a at 0") }
    if (sorted[1] != "b") { throw Exception("expected b at 1") }
    if (sorted[2] != "c") { throw Exception("expected c at 2") }
}

@Test
func testTopologicalSortDiamondDependency(): Unit {
    let packages = buildPackages([
        ("base", []),
        ("left", [("base", "../base")]),
        ("right", [("base", "../base")]),
        ("top", [("left", "../left"), ("right", "../right")])
    ])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())

    if (sorted.size != 4) { throw Exception("expected 4") }
    if (sorted[0] != "base") { throw Exception("expected base at 0") }
    if (idxOf(sorted, "left") >= idxOf(sorted, "top")) { throw Exception("left < top") }
    if (idxOf(sorted, "right") >= idxOf(sorted, "top")) { throw Exception("right < top") }
}

@Test
func testTopologicalSortNoDependencies(): Unit {
    let packages = buildPackages([
        ("x", []),
        ("y", []),
        ("z", [])
    ])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())
    if (sorted.size != 3) { throw Exception("expected 3") }
}

@Test
func testTopologicalSortCycleDetection(): Unit {
    let packages = buildPackages([
        ("a", [("b", "../b")]),
        ("b", [("a", "../a")])
    ])
    let graph = DepGraph(packages)
    graph.build()
    match (graph.topologicalSort()) {
        case Some(_) => throw Exception("expected cycle detection")
        case None => ()
    }
}

@Test
func testTopologicalSortIgnoresNonWorkspaceDeps(): Unit {
    let packages = buildPackages([
        ("a", []),
        ("b", [("a", "../a"), ("external", "../external")])
    ])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())
    if (sorted.size != 2) { throw Exception("expected 2") }
    if (sorted[0] != "a") { throw Exception("expected a at 0") }
    if (sorted[1] != "b") { throw Exception("expected b at 1") }
}

@Test
func testTopologicalSortComplexGraph(): Unit {
    let packages = buildPackages([
        ("common", []),
        ("utils", [("common", "../common")]),
        ("core", [("common", "../common"), ("utils", "../utils")]),
        ("api", [("core", "../core")]),
        ("cli", [("api", "../api"), ("utils", "../utils")])
    ])
    let graph = DepGraph(packages)
    graph.build()
    let sorted = unwrapSorted(graph.topologicalSort())

    if (sorted.size != 5) { throw Exception("expected 5") }
    if (idxOf(sorted, "common") >= idxOf(sorted, "utils")) { throw Exception("common < utils") }
    if (idxOf(sorted, "common") >= idxOf(sorted, "core")) { throw Exception("common < core") }
    if (idxOf(sorted, "utils") >= idxOf(sorted, "core")) { throw Exception("utils < core") }
    if (idxOf(sorted, "core") >= idxOf(sorted, "api")) { throw Exception("core < api") }
    if (idxOf(sorted, "api") >= idxOf(sorted, "cli")) { throw Exception("api < cli") }
    if (idxOf(sorted, "utils") >= idxOf(sorted, "cli")) { throw Exception("utils < cli") }
}
