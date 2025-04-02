//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftParserDiagnostics

let path: String
if CommandLine.arguments.count > 1 {
    path = CommandLine.arguments[1]
} else {
    print("Enter a swift file path (or blank for default):")
    print("> ", terminator: "")
    path = readLine(strippingNewline: true) ?? ""
}

let source = if path.isEmpty {
    """
    func Greet() {
        print("Hello, World!")
    

    func add(a: Int, b: Int) -> Int {
        return a + b
    }

    func ProcessData() -> String {
        return "Processed"
    }
    """
} else {
    try String(contentsOfFile: path, encoding: .utf8)
}

print("")
print("Original source:")
print("----------------")
print("")
print(source)
print("")

let syntaxTree = Parser.parse(source: source)
let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: syntaxTree)

print("Diagnostics:")
print("-----------------")
print("")
print(diagnostics)
print("")
