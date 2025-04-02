//
//  Interpreter.swift
//  REPL
//
//  Created by Nick Lockwood on 18/03/2025.
//

import SwiftSyntax
import SwiftDiagnostics

class Interpreter: SyntaxAnyVisitor {
    private var result: Variant = .undefined
    private var variables: [String: Variant] = [:]
    var diagnostics: [Diagnostic] = []

    func evaluate(_ syntax: SyntaxProtocol) -> Variant {
        result = .undefined
        walk(syntax)
        return result
    }

    // MARK: Expressions

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .number(Double(node.literal.text) ?? .nan)
        return .skipChildren
    }

    override func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .number(Double(node.literal.text) ?? .nan)
        return .skipChildren
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .boolean(node.literal.tokenKind == .keyword(.true))
        return .skipChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        result = .string(node.segments.map(\.trimmedDescription).joined())
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if let value = variables[node.baseName.text] {
            result = value
        } else {
            result = .undefined
            diagnostics.append(node.error("undefined variable '\(node.trimmed)'"))
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = evaluate(node.calledExpression)
        guard case let .function(function) = callee else {
            diagnostics.append(node.error("'\(callee)' is not a function"))
            return .skipChildren
        }
        let arguments = node.arguments.map { evaluate($0.expression) }
        let previous = variables
        defer { variables = previous }
        for (i, parameter) in function.signature.parameterClause.parameters.enumerated() {
            let name = (parameter.secondName ?? parameter.firstName).text
            guard i < arguments.count else {
                diagnostics.append(node.error("missing argument '\(name)'"))
                return .skipChildren
            }
            if name != "_" { variables[name] = arguments[i] }
        }
        result = function.body.map(evaluate) ?? .undefined
        return .skipChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let lhs = evaluate(node.leftOperand)
        let rhs = evaluate(node.rightOperand)

        switch (lhs, rhs, node.operator.trimmedDescription) {
        case let (.number(l), .number(r), "+"): result = .number(l + r)
        case let (.number(l), .number(r), "-"): result = .number(l - r)
        case let (.number(l), .number(r), "*"): result = .number(l * r)
        case let (.number(l), .number(r), "/"): result = .number(l / r)
        case let (.boolean(l), .boolean(r), "&&"): result = .boolean(l && r)
        case let (.boolean(l), .boolean(r), "||"): result = .boolean(l || r)
        case let (l, r, "<="): result = .boolean(l <= r)
        case let (l, r, ">="): result = .boolean(l >= r)
        case let (l, r, "<"): result = .boolean(l < r)
        case let (l, r, ">"): result = .boolean(l > r)
        case let (l, r, "!="): result = .boolean(l != r)
        case let (l, r, "=="): result = .boolean(l == r)
        case (.string, _, "+"), (_, .string, "+"): result = .string("\(lhs)\(rhs)")
        case (.undefined, _, _), (_, .undefined, _): result = .undefined
        default: diagnostics.append(node.error("invalid expression: \(node.trimmed)"))
        }
        
        return .skipChildren
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let value = evaluate(node.expression)

        switch (node.operator.text, value) {
        case let ("-", .number(n)): result = .number(-n)
        case let ("!", .boolean(b)): result = .boolean(!b)
        default: diagnostics.append(node.error("type mismatch '\(node.trimmed)'"))
        }

        return .skipChildren
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        if node.conditions.allSatisfy({
            switch $0.condition {
            case let .expression(expression):
                return evaluate(expression) == .boolean(true)
            default:
                diagnostics.append(node.error("unsupported syntax '\($0.condition.trimmed)'"))
                return false
            }
        }) {
            result = evaluate(node.body)
        } else if let elseBody = node.elseBody {
            result = evaluate(elseBody)
        }

        return .skipChildren
    }

    // MARK: Declarations

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            switch binding.pattern.as(PatternSyntaxEnum.self) {
            case let .identifierPattern(identifier):
                let value = binding.initializer.map { evaluate($0.value) }
                variables[identifier.identifier.text] = value ?? .undefined
            default:
                diagnostics.append(node.error("unsupported syntax '\(binding.pattern.kind)'"))
            }
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        variables[node.name.text] = .function(node)
        return .skipChildren
    }

    // MARK: Unsupported

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        diagnostics.append(node.error("unsupported syntax '\(node.kind)'"))
        return .visitChildren
    }

    // MARK: Ignored

    override open func visit(_ token: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: ExpressionStmtSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: TupleExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }
}
