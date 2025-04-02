//
//  Interpreter.swift
//  REPL
//
//  Created by Nick Lockwood on 18/03/2025.
//

import SwiftSyntax
import SwiftDiagnostics

class Preprocessor: SyntaxRewriter {
    private var diagnostics: [Diagnostic] = []

    static func process(_ syntax: inout SourceFileSyntax) -> [Diagnostic] {
        let processor = Preprocessor()
        syntax = processor.visit(syntax)
        return processor.diagnostics
    }

    override func visit(_ node: TypeAnnotationSyntax) -> TypeAnnotationSyntax {
        diagnostics.append(node.error("unsupported syntax '\(node.trimmed)'"))
        return node
    }

    override func visit(_ node: ReturnClauseSyntax) -> ReturnClauseSyntax {
        diagnostics.append(node.error("unsupported syntax '\(node.trimmed)'"))
        return node
    }

    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        if node.colon.presence == .present {
            diagnostics.append(node.error("unsupported syntax ': \(node.type.trimmed)'"))
        }
        return node
            .with(\.colon.presence, .present)
            .with(\.type, TypeSyntax(IdentifierTypeSyntax(
                name: .identifier("Any"),
                trailingTrivia: .space
            )))
    }
}
