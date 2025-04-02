//
//  Eval.swift
//  SwiftSyntaxTalk
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftSyntax
import SwiftParser
import SwiftOperators
import SwiftParserDiagnostics
import SwiftDiagnostics

print("Type expressions to see the result. Type 'exit' to quit.")

let interpreter = Interpreter(viewMode: .fixedUp)
while true {
    print("> ", terminator: "")
    guard let input = readLine(), input.lowercased() != "exit" else {
        break
    }
    let sourceSyntax = Parser.parse(source: input)
    var diagnostics = ParseDiagnosticsGenerator.diagnostics(for: sourceSyntax)
    let operatorTable = OperatorTable.standardOperators
    let foldedSyntax = operatorTable.foldAll(sourceSyntax) { error in
        diagnostics.append(error.asDiagnostic)
    }
    let result = interpreter.evaluate(foldedSyntax)
    diagnostics += interpreter.diagnostics
    interpreter.diagnostics.removeAll()
    for diagnostic in diagnostics { print(diagnostic) }
    if diagnostics.contains(where: { $0.diagMessage.severity == .error }) {
        continue
    }
    print("= \(result)")
}

enum Variant: Equatable {
    case undefined
    case number(Double)
    case boolean(Bool)
    case string(String)
}

extension Variant: CustomStringConvertible {
    var description: String {
        switch self {
        case .undefined: "undefined"
        case let .number(value): "\(value)"
        case let .boolean(value): "\(value)"
        case let .string(value): value
        }
    }
}

class Interpreter: SyntaxAnyVisitor {
    private var result: Variant = .undefined
    private var variables: [String: Variant] = [:]
    var diagnostics: [Diagnostic] = []

    func evaluate(_ syntax: SyntaxProtocol) -> Variant {
        result = .undefined
        walk(syntax)
        return result
    }

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

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let lhs = evaluate(node.leftOperand)
        let rhs = evaluate(node.rightOperand)

        switch (lhs, rhs, node.operator.trimmedDescription) {
        case let (.number(l), .number(r), "+"): result = .number(l + r)
        case let (.number(l), .number(r), "-"): result = .number(l - r)
        case let (.number(l), .number(r), "*"): result = .number(l * r)
        case let (.number(l), .number(r), "/"): result = .number(l / r)
        case let (.number(l), .number(r), "<="): result = .boolean(l <= r)
        case let (.number(l), .number(r), ">="): result = .boolean(l >= r)
        case let (.number(l), .number(r), "<"): result = .boolean(l < r)
        case let (.number(l), .number(r), ">"): result = .boolean(l > r)
        case let (l, r, "!="): result = .boolean(l != r)
        case let (l, r, "=="): result = .boolean(l == r)
        case (.string, _, "+"), (_, .string, "+"): result = .string("\(lhs)\(rhs)")
        case (.undefined, _, _), (_, .undefined, _): result = .undefined
        default: diagnostics.append(node.error("invalid expression: \(node.trimmed)"))
        }

        return .skipChildren
    }

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

    // MARK: Unsupported

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        diagnostics.append(node.error("unsupported syntax '\(node.kind)'"))
        return .visitChildren
    }

    // MARK: Ignored

    override open func visit(_ token: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override open func visit(_ token: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
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

extension SyntaxProtocol {
    func error(_ message: String) -> Diagnostic {
        .init(node: self, message: Message(message: message))
    }
}

struct Message: DiagnosticMessage {
    var message: String
    var severity: DiagnosticSeverity = .error
    var diagnosticID: MessageID {
        .init(domain: "Interpreter", id: message)
    }
}
