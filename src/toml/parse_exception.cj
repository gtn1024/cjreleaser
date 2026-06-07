// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

class ParseException <: Exception {
    public init(message: String) {
        super(message)
    }

    public init(message: String, pos: Position) {
        super("toml: line ${pos.line}: ${message}")
    }

    public init(message: String, pos: Position, lastKey: String) {
        super("toml: line ${pos.line} (last key ${lastKey}): ${message}")
    }

    protected override func getClassName(): String {
        return "ParseException"
    }
}
