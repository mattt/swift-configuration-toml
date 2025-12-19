// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TOMLProvider",
            targets: ["TOMLProvider"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
        .package(url: "https://github.com/mattt/swift-toml.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TOMLProvider",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "TOML", package: "swift-toml"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "TOMLProviderTests",
            dependencies: [
                "TOMLProvider",
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
