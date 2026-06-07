// Adapted from cjpm (Cangjie Package Manager)
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 with Runtime Library Exception.
// Modifications copyright 2025 cjreleaser contributors.

package cjreleaser.toml

let SPECIAL_CHAR_ESCAPES: Array<String> = ["\\u0000", "\\u0001", "\\u0002", "\\u0003", "\\u0004", "\\u0005", "\\u0006",
    "\\u0007", "\\b", "\\t", "\\n", "\\u000b", "\\f", "\\r", "\\u000e", "\\u000f", "\\u0010", "\\u0011", "\\u0012",
    "\\u0013", "\\u0014", "\\u0015", "\\u0016", "\\u0017", "\\u0018", "\\u0019", "\\u001a", "\\u001b", "\\u001c",
    "\\u001d", "\\u001e", "\\u001f", "", "", "\\\"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
    "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
    "", "", "", "", "", "", "", "", "", "", "", "\\\\", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
    "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "\\u007f"]

func quotedReplace(s: String): String {
    let sb = StringBuilder()
    for (r in s.runes()) {
        let codePoint = Int64(UInt32(r))
        if (codePoint < SPECIAL_CHAR_ESCAPES.size && SPECIAL_CHAR_ESCAPES[codePoint] != "") {
            sb.append(SPECIAL_CHAR_ESCAPES[codePoint])
        } else {
            sb.append(r)
        }
    }
    return sb.toString()
}

let DATETIME_REPLACER = [
    ("z", "Z"),
    ("t", "T"),
    (" ", "T")
]

func datetimeReplace(s: String): String {
    var rs = s
    for (r in DATETIME_REPLACER) {
        rs = rs.replace(r[0], r[1])
    }
    return rs
}
