// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "zippy",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "zippy", targets: ["Zippy"]),
        .library(name: "MenuManagement", targets: ["MenuManagement"]),
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        // Add any dependencies here
    ],
    targets: [
        .executableTarget(
            name: "Zippy",
            dependencies: ["MenuManagement", "Networking"],
            path: "Sources"
        ),
        .target(
            name: "MenuManagement",
            dependencies: ["Networking"],
            path: "Modules/MenuManagement"
        ),
        .target(
            name: "Networking",
            dependencies: [],
            path: "Modules/Networking"
        )
    ]
)
