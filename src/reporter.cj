package cjreleaser

import std.collection.*
import termcolor.*

public class CheckReport {
    public var results: ArrayList<CheckResult> = ArrayList<CheckResult>()
    public var order: Array<String> = Array<String>()
    public var isWorkspace: Bool = false
    let c = createColors(true)

    public func printReport(): Unit {
        if (isWorkspace) {
            println("[cjreleaser] Workspace with ${order.size} package(s) to publish:")
        } else {
            println("[cjreleaser] Single package mode:")
        }

        var i = 1
        for (name in order) {
            let result = findResult(name)

            if (let Some(r) <- result) {
                let statusStr = getStatusStr(r)
                println("  ${i}. ${r.packageName}  ${statusStr}")

                for (err in r.errors) {
                    println("     ${c.red("✗")} ${err}")
                }
                for (warn in r.warnings) {
                    println("     ${c.yellow("⚠")} ${warn}")
                }
            }
            i = i + 1
        }

        let (okCount, warnCount, errCount) = countResults()
        println("")
        if (errCount > 0) {
            println("[cjreleaser] Summary: ${c.green("${okCount} ok")}, ${c.yellow("${warnCount} warning(s)")}, ${c.red("${errCount} error(s)")}")
        } else if (warnCount > 0) {
            println("[cjreleaser] Summary: ${c.green("${okCount} ok")}, ${c.yellow("${warnCount} warning(s)")}, ${errCount} error(s)")
        } else {
            println("[cjreleaser] Summary: ${c.green("${okCount} ok")}, ${warnCount} warning(s), ${errCount} error(s)")
        }
    }

    func findResult(name: String): ?CheckResult {
        for (r in results) {
            if (r.packageName == name) {
                return r
            }
        }
        return None
    }

    func getStatusStr(r: CheckResult): String {
        if (r.status == "error") {
            return c.red("✗")
        }
        if (r.status == "warn") {
            return c.yellow("⚠")
        }
        return c.green("✓")
    }

    func countResults(): (Int64, Int64, Int64) {
        var ok: Int64 = 0
        var warn: Int64 = 0
        var err: Int64 = 0
        for (r in results) {
            if (r.status == "error") {
                err = err + 1
            } else if (r.status == "warn") {
                warn = warn + 1
            } else {
                ok = ok + 1
            }
        }
        return (ok, warn, err)
    }

    public func hasErrors(): Bool {
        for (r in results) {
            if (r.hasErrors()) {
                return true
            }
        }
        return false
    }
}
