// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-configuration-toml",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "ConfigurationTOML",
            targets: ["ConfigurationTOML"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
        .package(url: "https://github.com/mattt/swift-toml.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ConfigurationTOML",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "TOML", package: "swift-toml"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "ConfigurationTOMLTests",
            dependencies: [
                "ConfigurationTOML",
                .product(name: "ConfigurationTesting", package: "swift-configuration"),
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
