// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownReader",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/smittytone/HighlighterSwift", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownReader",
            dependencies: [
                .product(name: "Highlighter", package: "HighlighterSwift"),
            ],
            path: "Sources/MarkdownReader"
        )
    ]
)
