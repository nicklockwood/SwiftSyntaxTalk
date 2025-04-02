//
//  Diagnostics.swift
//  REPL
//
//  Created by Nick Lockwood on 18/03/2025.
//

import SwiftSyntax
import SwiftDiagnostics

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
