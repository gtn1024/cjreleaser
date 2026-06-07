package cjreleaser

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*

func assertTrans(condition: Bool, msg: String): Unit {
    if (!condition) {
        throw Exception(msg)
    }
}

@Test
func testTransformRewritesPathDepToVersion(): Unit {
    let current = PackageInfo()
    current.name = "lib-b"
    current.version = "1.0.0"
    let depA = DepInfo()
    depA.path = "../lib-a"
    current.dependencies.add("lib-a", depA)

    let depC = DepInfo()
    depC.path = "../lib-c"
    current.dependencies.add("lib-c", depC)

    let ws = WorkspaceInfo()
    let pkgA = PackageInfo()
    pkgA.name = "lib-a"
    pkgA.version = "2.0.0"
    pkgA.organization = "my-org"
    ws.packages.add("lib-a", pkgA)

    let pkgC = PackageInfo()
    pkgC.name = "lib-c"
    pkgC.version = "0.5.0"
    pkgC.organization = ""
    ws.packages.add("lib-c", pkgC)

    let input = "[package]\nname = \"lib-b\"\nversion = \"1.0.0\"\n\n[dependencies]\nlib-a = { path = \"../lib-a\" }\nlib-c = { path = \"../lib-c\" }\n"
    let result = rewritePathDeps(input, current, ws)

    assertTrans(result.contains("lib-a = { version = \"2.0.0\", organization = \"my-org\" }"),
        "expected lib-a rewritten with org")
    assertTrans(result.contains("lib-c = { version = \"0.5.0\" }"),
        "expected lib-c rewritten without org")
    assertTrans(!result.contains("path = "), "expected no path deps remaining")
}

@Test
func testTransformNoPathDeps(): Unit {
    let current = PackageInfo()
    current.name = "lib-a"
    current.version = "1.0.0"

    let ws = WorkspaceInfo()
    ws.packages.add("lib-a", current)

    let input = "[package]\nname = \"lib-a\"\nversion = \"1.0.0\"\n\n[dependencies]\ncjxe = \"0.3.0\"\n"
    let result = rewritePathDeps(input, current, ws)

    assertTrans(result == input, "expected no changes")
}

@Test
func testTransformMixedDeps(): Unit {
    let current = PackageInfo()
    current.name = "app"
    current.version = "1.0.0"
    let depLocal = DepInfo()
    depLocal.path = "../lib"
    current.dependencies.add("lib", depLocal)
    let depRemote = DepInfo()
    depRemote.version = "0.3.0"
    current.dependencies.add("cjxe", depRemote)

    let ws = WorkspaceInfo()
    let pkgLib = PackageInfo()
    pkgLib.name = "lib"
    pkgLib.version = "3.0.0"
    pkgLib.organization = "acme"
    ws.packages.add("lib", pkgLib)

    let input = "[package]\nname = \"app\"\nversion = \"1.0.0\"\n\n[dependencies]\nlib = { path = \"../lib\" }\ncjxe = \"0.3.0\"\n"
    let result = rewritePathDeps(input, current, ws)

    assertTrans(result.contains("lib = { version = \"3.0.0\", organization = \"acme\" }"),
        "expected lib rewritten")
    assertTrans(result.contains("cjxe = \"0.3.0\""),
        "expected cjxe preserved")
}

@Test
func testTransformPreservesOtherFields(): Unit {
    let current = PackageInfo()
    current.name = "app"
    current.version = "1.0.0"
    let depLocal = DepInfo()
    depLocal.path = "../lib"
    current.dependencies.add("lib", depLocal)

    let ws = WorkspaceInfo()
    let pkgLib = PackageInfo()
    pkgLib.name = "lib"
    pkgLib.version = "1.0.0"
    ws.packages.add("lib", pkgLib)

    let input = "[package]\nname = \"app\"\nversion = \"1.0.0\"\ndescription = \"My app\"\noutput-type = \"executable\"\n\n[dependencies]\nlib = { path = \"../lib\" }\n\n[target.aarch64-unknown-linux-gnu]\n  compile-option = \"-ldl\"\n"
    let result = rewritePathDeps(input, current, ws)

    assertTrans(result.contains("description = \"My app\""), "expected description preserved")
    assertTrans(result.contains("output-type = \"executable\""), "expected output-type preserved")
    assertTrans(result.contains("compile-option = \"-ldl\""), "expected target section preserved")
}
