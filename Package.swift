// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Zippy",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // The main executable uses the Zippy target, which depends on Networking.
        .executable(name: "zippy", targets: ["zippy"]),
        // Expose the Networking module as a library.
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        // Add external dependencies here if necessary.
    ],
    targets: [
        .executableTarget(
            name: "zippy",
            dependencies: ["Networking", "MenuManagement"],
            path: "Sources/Zippy"  // Adjust if your source directory is different.
        ),
        .target(
            name: "Networking",
            path: "src/Networking"
        ),
        .target(
            name: "MenuManagement",
            dependencies: ["Networking"],
            path: "Sources/ZippyCore/MenuManagement"
        ),
        .testTarget(
            name: "ZippyTests",
            dependencies: ["zippy", "Networking"],
            path: "Tests"
        )
    ]
) 