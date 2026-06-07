// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

public interface TomlType <: ToString {
    func typeString(): String
}

struct TomlBaseType <: TomlType & Equatable<TomlBaseType> {
    let btype: String

    public init(btype: String) {
        this.btype = btype
    }

    public func toString(): String {
        return typeString()
    }

    public func typeString(): String {
        return btype
    }

    public operator func ==(rhs: TomlBaseType): Bool {
        return btype == rhs.btype
    }

    public operator func !=(rhs: TomlBaseType): Bool {
        return btype != rhs.btype
    }
}
