//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import Foundation

let source = """
func sayHello() { print("Hello,

func add(a: Int, b: Int) Int { a b

func processData( -> String Processed" }
"""

let syntaxTree = Parser.parse(source: source)
let visitor = FunctionFinder(viewMode: .fixedUp)
visitor.walk(syntaxTree)

final class FunctionFinder: SyntaxVisitor {
    override func visit(_ node: FunctionDeclSyntax)
        -> SyntaxVisitorContinueKind {

        print("Found function: '\(node.name.text)'")
        return .visitChildren
    }
}
