// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AsyncActionArchitecture",
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
