// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "HelloWorld",
    targets: [
        .target(
            name: "HelloWorld",
            path: "Sources/HelloWorld"
        ),
        .testTarget(
            name: "HelloWorldTests",
            dependencies: ["HelloWorld"],
            path: "Tests/HelloWorldTests"
        ),
    ]
)
