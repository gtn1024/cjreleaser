package cjreleaser

import std.collection.*
import std.io.*
import std.time.*
import std.core.sleep
import stdx.net.http.*
import stdx.net.tls.*
import stdx.encoding.json.*

let REGISTRY_BASE = "https://pkg.cangjie-lang.cn"

public func waitForPackagePublish(name: String, version: String, organization: String, timeoutSecs: Int64, intervalSecs: Int64): Bool {
    let searchUrl = "${REGISTRY_BASE}/v1/artifact/searchPackages?pageNum=1&pageSize=10&orderField=5&name=${name}"
    let tlsConfig = TlsClientConfig()
    let client = ClientBuilder()
        .tlsConfig(tlsConfig)
        .readTimeout(30 * Duration.second)
        .build()

    let startTime = DateTime.now()
    var elapsed: Int64 = 0

    while (elapsed < timeoutSecs * 1000000000) {
        try {
            let request = HttpRequestBuilder().url(searchUrl).get().build()
            let response = client.send(request)
            if (response.status == UInt16(200)) {
                let bodyBytes = readAllBytes(response.body)
                let body = String.fromUtf8(bodyBytes)
                if (checkVersionInSearchResult(body, version)) {
                    println("[cjreleaser] Package '${name}-${version}' is now indexed on central repository")
                    return true
                }
            }
        } catch (_: Exception) {}

        println("[cjreleaser] Waiting for '${name}-${version}' to be indexed (${elapsed / 1000000000}s / ${timeoutSecs}s)...")
        sleep(Duration.second * intervalSecs)
        let now = DateTime.now()
        let diff = now - startTime
        elapsed = diff.toNanoseconds()
    }

    eprintln("Error: timed out waiting for '${name}-${version}' to be indexed after ${timeoutSecs}s")
    return false
}

func checkVersionInSearchResult(body: String, version: String): Bool {
    try {
        let parsed = JsonValue.fromStr(body)
        let root = parsed.asObject()
        let data = root["data"].asObject()
        let results = data["results"].asArray()
        if (results.size() > 0) {
            let pkg = results[0].asObject()
            let latestVer = pkg["latestVersion"].asString()
            if (latestVer.getValue() == version) {
                return true
            }
        }
    } catch (_: Exception) {}
    return false
}

func readAllBytes(stream: InputStream): Array<Byte> {
    let buffer = ArrayList<Byte>()
    let chunk = Array<Byte>(4096, repeat: 0)
    while (true) {
        let n = stream.read(chunk)
        if (n <= 0) {
            break
        }
        for (i in 0..n) {
            buffer.add(chunk[i])
        }
    }
    return buffer.toArray()
}
