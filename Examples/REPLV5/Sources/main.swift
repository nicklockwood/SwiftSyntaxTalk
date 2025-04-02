//
//  main.swift
//  REPL
//
//  Created by Nick Lockwood on 01/02/2025.
//

import SwiftParser
import SwiftOperators
import SwiftParserDiagnostics

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
    if result != .undefined {
        print("= \(result)")
    }
}
