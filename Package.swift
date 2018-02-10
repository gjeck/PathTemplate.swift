// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "PathTemplate",
    products: [
        .library(name: "PathTemplate",
                 targets: ["PathTemplate"]),
    ],
    targets: [
        .target(name: "PathTemplate",
                dependencies: []),
        .testTarget(name: "PathTemplateTests",
                    dependencies: ["PathTemplate"]),
    ]
)
