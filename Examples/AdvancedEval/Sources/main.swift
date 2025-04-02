//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import SwiftOperators

print("Type expressions or variable assignments. Type 'exit' to quit.")

var variables: [String: ValueType] = [:]

while true {
    print("> ", terminator: "")
    guard let input = readLine(), input.lowercased() != "exit" else {
        break
    }
    do {
        let sourceSyntax = Parser.parse(source: input)
        let operatorTable = OperatorTable.standardOperators
        let foldedSyntax = try operatorTable.foldAll(sourceSyntax)
        guard let sourceSyntax = SourceFileSyntax(foldedSyntax),
              sourceSyntax.statements.count == 1,
              let itemSyntax = sourceSyntax.statements.first?.item
        else {
            throw EvalError.invalidExpression
        }
        switch itemSyntax {
        case let .expr(exprSyntax):
            let evaluator = ExpressionEvaluator(variables: variables)
            let result = evaluator.evaluate(exprSyntax)
            print("= \(try result.get())")
        case let .decl(declSyntax):
            guard let varDecl = declSyntax.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let initializer = binding.initializer?.value
            else {
                fallthrough
            }
            let evaluator = ExpressionEvaluator(variables: variables)
            let result = evaluator.evaluate(initializer)
            variables[identifier] = result
            print("\(identifier) = \(try result.get())")
        default:
            throw EvalError.invalidExpression
        }
    } catch {
        print("Error: \(error)")
    }
}

class ExpressionEvaluator: SyntaxVisitor {
    private var result: ValueType = .error(.invalidExpression)
    private var variables: [String: ValueType]

    init(variables: [String: ValueType] = [:]) {
        self.variables = variables
        super.init(viewMode: .fixedUp)
    }

    func evaluate(_ syntax: ExprSyntax) -> ValueType {
        self.walk(syntax)
        return result
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .number(Double(node.literal.text) ?? 0)
        return .skipChildren
    }

    override func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .number(Double(node.literal.text) ?? 0)
        return .skipChildren
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .boolean(node.literal.text == "true")
        return .skipChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .string(node.segments.description)
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.baseName.text
        result = variables[name] ?? .error(.undefinedVariable(name))
        return .skipChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let lhs = ExpressionEvaluator(variables: variables).evaluate(node.leftOperand)
        let rhs = ExpressionEvaluator(variables: variables).evaluate(node.rightOperand)

        result = switch (lhs, rhs, node.operator.trimmedDescription) {
        case let (.number(l), .number(r), "+"): .number(l + r)
        case let (.number(l), .number(r), "-"): .number(l - r)
        case let (.number(l), .number(r), "*"): .number(l * r)
        case let (.number(l), .number(r), "/"): .number(l / r)
        case let (.string(l), .string(r), "+"): .string(l + r)
        case let (.boolean(l), .boolean(r), "&&"): .boolean(l && r)
        case let (.boolean(l), .boolean(r), "||"): .boolean(l || r)
        case let (.number(l), .number(r), "=="): .boolean(l == r)
        case let (.string(l), .string(r), "=="): .boolean(l == r)
        case let (.boolean(l), .boolean(r), "=="): .boolean(l == r)
        case let (.number(l), .number(r), "!="): .boolean(l != r)
        case let (.string(l), .string(r), "!="): .boolean(l == r)
        case let (.boolean(l), .boolean(r), "!="): .boolean(l == r)
        case let (.number(l), .number(r), "<"): .boolean(l < r)
        case let (.number(l), .number(r), ">"): .boolean(l > r)
        case let (.number(l), .number(r), "<="): .boolean(l <= r)
        case let (.number(l), .number(r), ">="): .boolean(l >= r)
        default: .error(.typeMismatch)
        }

        return .skipChildren
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let value = ExpressionEvaluator(variables: variables).evaluate(node.expression)

        switch (node.operator.text, value) {
        case ("-", .number(let num)): result = .number(-num)
        case ("!", .boolean(let bool)): result = .boolean(!bool)
        default: break
        }

        return .skipChildren
    }
}

enum EvalError: Error {
    case invalidExpression
    case undefinedVariable(String)
    case typeMismatch
}

enum ValueType {
    case number(Double)
    case string(String)
    case boolean(Bool)
    case error(EvalError)

    func get() throws -> Any {
        switch self {
        case let .boolean(value): value
        case let .number(value): value
        case let .string(value): value
        case let .error(error): throw error
        }
    }
}
