// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

public class LexException <: Exception {
    public init() {
        super()
    }

    public init(message: String) {
        super(message)
    }

    protected override func getClassName(): String {
        return "LexException"
    }
}
