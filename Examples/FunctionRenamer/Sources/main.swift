//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import Foundation

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
    }

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

class FunctionRenamer: SyntaxRewriter {
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let originalName = node.name.text

        // Skip names that already start with a lowercase letter
        guard let first = originalName.first, first.isUppercase else {
            return DeclSyntax(node)
        }

        // Modify name
        let newName = "\(first.lowercased())\(originalName.dropFirst())"
        return DeclSyntax(node.with(\.name, .identifier(newName)))
    }
}

let syntaxTree = Parser.parse(source: source)
let rewriter = FunctionRenamer()
let rewrittenTree = rewriter.visit(syntaxTree)

print("Rewritten source:")
print("-----------------")
print("")
print(rewrittenTree)
print("")
