// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTodoCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Storage", targets: ["Storage"]),
        .library(name: "ViewModels", targets: ["ViewModels"]),
    ],
    targets: [
        .target(name: "Models", path: "Sources/Models"),
        .target(name: "Storage", dependencies: ["Models"], path: "Sources/Storage"),
        .target(name: "ViewModels", dependencies: ["Models", "Storage"], path: "Sources/ViewModels"),
        .testTarget(name: "ModelsTests", dependencies: ["Models"], path: "Tests/ModelsTests"),
        .testTarget(name: "StorageTests", dependencies: ["Storage", "Models"], path: "Tests/StorageTests"),
    ]
)
