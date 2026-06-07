// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

/**
 * TomlException class.
 */
public class TomlException <: Exception {
    /**
     * Create a new TomlException instance.
     *
     *
     */
    public init() {
        super()
    }

    /**
     * Create a new TomlException instance.
     * Construction with parameters.
     *
     * @param message exception message.
     *
     *
     */
    public init(message: String) {
        super(message)
    }

    /**
     * Get class name.
     *
     * @return class name.
     *
     *
     */
    protected override func getClassName(): String {
        return "TomlException"
    }
}
