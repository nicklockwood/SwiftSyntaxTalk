// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "eval",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "diagnostics",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
            ]
        ),
    ]
)
