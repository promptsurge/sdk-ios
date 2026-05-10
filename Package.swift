// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PromptSurge",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "PromptSurge", targets: ["PromptSurge"]),
    ],
    targets: [
        .target(
            name: "PromptSurge",
            path: "Sources/PromptSurge"
        ),
    ]
)
