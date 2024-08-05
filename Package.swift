// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "async-action-architecture",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .visionOS(.v1),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "AsyncActionArchitecture",
            targets: ["AsyncActionArchitecture"]
        ),
    ],
    targets: [
        .target(
            name: "AsyncActionArchitecture"
        ),
        .testTarget(
            name: "AsyncActionArchitectureTests",
            dependencies: ["AsyncActionArchitecture"]
        ),
    ]
)
