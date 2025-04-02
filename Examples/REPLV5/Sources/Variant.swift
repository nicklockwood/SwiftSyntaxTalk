//
//  Variant.swift
//  REPL
//
//  Created by Nick Lockwood on 18/03/2025.
//

import SwiftSyntax

enum Variant {
    case undefined
    case number(Double)
    case boolean(Bool)
    case string(String)
    case function(FunctionDeclSyntax)
}

extension Variant: Comparable {
    static func < (lhs: Variant, rhs: Variant) -> Bool {
        switch (lhs, rhs) {
        case let (.number(l), .number(r)): l < r
        case let (.string(l), .string(r)): l < r
        default: false
        }
    }
}

extension Variant: CustomStringConvertible {
    var description: String {
        switch self {
        case .undefined: "undefined"
        case let .number(value): "\(value)"
        case let .boolean(value): "\(value)"
        case let .string(value): value
        case let .function(function): "\(function)"
        }
    }
}
