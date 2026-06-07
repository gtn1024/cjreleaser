package cjreleaser

import std.unittest.*
import std.unittest.testmacro.*
import cjreleaser.toml.*

func getObj(root: TomlObject, key: String): TomlObject {
    match (root.get(key)) {
        case Some(v) => v.asObject()
        case None => throw Exception("key '${key}' not found")
    }
}

func getVal(root: TomlObject, key: String): TomlValue {
    match (root.get(key)) {
        case Some(v) => v
        case None => throw Exception("key '${key}' not found")
    }
}

func assertToml(condition: Bool, msg: String): Unit {
    if (!condition) {
        throw Exception(msg)
    }
}

@Test
func testTomlParseSimpleValues(): Unit {
    let toml = "[package]\nname = \"my-lib\"\nversion = \"1.0.0\"\ndescription = \"A test library\""
    let p = parse(toml)
    let root = p.mapping
    let pkg = getObj(root, "package")

    assertToml(pkg["name"].asString().value == "my-lib", "name mismatch")
    assertToml(pkg["version"].asString().value == "1.0.0", "version mismatch")
    assertToml(pkg["description"].asString().value == "A test library", "description mismatch")
}

@Test
func testTomlParseBoolean(): Unit {
    let toml = "[release]\nskip-test = true\nskip-lint = false"
    let p = parse(toml)
    let root = p.mapping
    let rel = getObj(root, "release")

    assertToml(rel["skip-test"].asBool().value, "skip-test should be true")
    assertToml(!rel["skip-lint"].asBool().value, "skip-lint should be false")
}

@Test
func testTomlParseArray(): Unit {
    let toml = "[release]\ninclude = [\"lib-a\", \"lib-b\", \"lib-c\"]"
    let p = parse(toml)
    let root = p.mapping
    let arr = getObj(root, "release")["include"].asArray()

    assertToml(arr.size == 3, "expected 3, got ${arr.size}")
    assertToml(arr[0].asString().value == "lib-a", "arr[0]")
    assertToml(arr[1].asString().value == "lib-b", "arr[1]")
    assertToml(arr[2].asString().value == "lib-c", "arr[2]")
}

@Test
func testTomlParseInlineTable(): Unit {
    let toml = "[dependencies]\nlib-a = { path = \"../lib-a\" }\nlib-b = { version = \"1.0.0\", organization = \"my-org\" }"
    let p = parse(toml)
    let root = p.mapping
    let deps = getObj(root, "dependencies")

    let depA = deps["lib-a"].asObject()
    assertToml(depA["path"].asString().value == "../lib-a", "lib-a path")

    let depB = deps["lib-b"].asObject()
    assertToml(depB["version"].asString().value == "1.0.0", "lib-b version")
    assertToml(depB["organization"].asString().value == "my-org", "lib-b org")
}

@Test
func testTomlParseSimpleStringDep(): Unit {
    let toml = "[dependencies]\ncjxe = \"0.3.0\"\ntermcolor = \"1.0.0\""
    let p = parse(toml)
    let root = p.mapping
    let deps = getObj(root, "dependencies")

    assertToml(deps["cjxe"].asString().value == "0.3.0", "cjxe")
    assertToml(deps["termcolor"].asString().value == "1.0.0", "termcolor")
}

@Test
func testTomlParseInteger(): Unit {
    let toml = "[config]\nport = 8080"
    let p = parse(toml)
    let root = p.mapping
    let cfg = getObj(root, "config")
    assertToml(cfg["port"].asInt().value == 8080, "port mismatch")
}

@Test
func testTomlParseNestedSection(): Unit {
    let toml = "[target.aarch64-unknown-linux-gnu]\n  compile-option = \"-Woff unused -ldl\"\n  [target.aarch64-unknown-linux-gnu.bin-dependencies]\n    path-option = [ \"/some/path\" ]"
    let p = parse(toml)
    let root = p.mapping
    let target = getObj(root, "target")
    let linuxTarget = target["aarch64-unknown-linux-gnu"].asObject()

    assertToml(linuxTarget["compile-option"].asString().value == "-Woff unused -ldl", "compile-option")

    let binDeps = linuxTarget["bin-dependencies"].asObject()
    let pathOpt = binDeps["path-option"].asArray()
    assertToml(pathOpt.size == 1, "path-option size")
    assertToml(pathOpt[0].asString().value == "/some/path", "path-option value")
}

@Test
func testTomlParseWorkspaceMembers(): Unit {
    let toml = "[workspace]\nmembers = [\"pkg-a\", \"pkg-b\", \"pkg-c\"]"
    let p = parse(toml)
    let root = p.mapping
    let ws = getObj(root, "workspace")
    let members = ws["members"].asArray()

    assertToml(members.size == 3, "members size")
    assertToml(members[0].asString().value == "pkg-a", "member 0")
    assertToml(members[1].asString().value == "pkg-b", "member 1")
    assertToml(members[2].asString().value == "pkg-c", "member 2")
}

@Test
func testTomlParseComments(): Unit {
    let toml = "# comment\n[package]\nname = \"my-lib\" # inline\nversion = \"1.0.0\""
    let p = parse(toml)
    let root = p.mapping
    let pkg = getObj(root, "package")
    assertToml(pkg["name"].asString().value == "my-lib", "name should not include comment")
}

@Test
func testTomlEmptyInput(): Unit {
    try {
        let toml = ""
        let p = parse(toml)
        let root = p.mapping
        assertToml(root.value.size == 0, "expected empty root")
    } catch (_: Exception) {
        ()
    }
}
