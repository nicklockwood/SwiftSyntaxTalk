//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import SwiftOperators

print("Type expressions to see the result. Type 'exit' to quit.")

let interpreter = Interpreter(viewMode: .fixedUp)
while true {
    print("> ", terminator: "")
    guard let input = readLine(), input.lowercased() != "exit" else {
        break
    }
    let sourceSyntax = Parser.parse(source: input)
    let operatorTable = OperatorTable.standardOperators
    let foldedSyntax = try operatorTable.foldAll(sourceSyntax)
    let result = interpreter.evaluate(foldedSyntax)
    print("= \(result)")
}

class Interpreter: SyntaxVisitor {
    private var result: Double = .nan

    func evaluate(_ syntax: SyntaxProtocol) -> Double {
        result = .nan
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
