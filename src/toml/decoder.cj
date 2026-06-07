// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

import std.io.*

public class Decoder {
    let r: InputStream

    public init(r: InputStream) {
        this.r = r
    }

    public func decode(): TomlObject {
        let sr = StringReader(r)
        let data = sr.readToEnd()
        let p = parse(data)
        return p.mapping
    }
}
