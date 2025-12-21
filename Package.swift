// swift-tools-version: 6.2

import PackageDescription

var traits: Set<Trait> = [
    .trait(
        name: "Reloading",
        description: "Adds support for reloading file provider variants, such as ReloadingTOMLProvider."
    )
]

// Disabled by default.
traits.insert(.default(enabledTraits: []))

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
    traits: traits,
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-configuration.git",
            from: "1.0.0",
            traits: [
                .defaults,
                .trait(name: "Reloading", condition: .when(traits: ["Reloading"])),
            ]
        ),
        .package(url: "https://github.com/mattt/swift-toml.git", from: "1.0.0"),

        // Added explicitly as a workaround for https://github.com/apple/swift-configuration/issues/89
        .package(url: "https://github.com/apple/swift-metrics", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "ConfigurationTOML",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "TOML", package: "swift-toml"),

                // Added explicitly as a workaround for https://github.com/apple/swift-configuration/issues/89
                .product(name: "Metrics", package: "swift-metrics"),
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
