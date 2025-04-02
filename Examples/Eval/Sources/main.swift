//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import SwiftOperators

let expression: String
if CommandLine.arguments.count > 1 {
    expression = CommandLine.arguments[1]
} else {
    print("Enter a swift expression:")
    print("> ", terminator: "")
    expression = readLine(strippingNewline: true) ?? ""
}

let sourceSyntax = Parser.parse(source: expression)
var operatorTable = OperatorTable.standardOperators
try operatorTable.addSourceFile(sourceSyntax)
let foldedSyntax = try operatorTable.foldAll(sourceSyntax)
let interpreter = Interpreter(viewMode: .fixedUp)
let result = interpreter.evaluate(foldedSyntax)
print("= \(result)")

class Interpreter: SyntaxVisitor {
    private var result: Double = .nan

    func evaluate(_ syntax: SyntaxProtocol) -> Double {
        walk(syntax)
        return result
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = Double(node.literal.text) ?? .nan
        return .skipChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let lhs = evaluate(node.leftOperand)
        let rhs = evaluate(node.rightOperand)

        switch node.operator.trimmedDescription {
        case "+": result = lhs + rhs
        case "-": result = lhs - rhs
        case "*": result = lhs * rhs
        case "/": result = lhs / rhs
        default: break
        }

        return .skipChildren
    }
}
