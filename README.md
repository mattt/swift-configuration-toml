# Swift Configuration TOML

A [TOML](https://toml.io) provider for the [Swift Configuration](https://github.com/apple/swift-configuration) framework,
built on [swift-toml](https://github.com/mattt/swift-toml) for spec-compliant parsing

## Requirements

- Swift 6.2+ / Xcode 26+
- macOS 15.0+ / iOS 18.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
    .package(url: "https://github.com/mattt/swift-configuration-toml.git", branch: "main")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Configuration", package: "swift-configuration"),
        .product(name: "ConfigurationTOML", package: "swift-configuration-toml")
    ],
    swiftSettings: [
        .interoperabilityMode(.Cxx)
    ]
)
```

## Usage

### Basic Usage

```swift
import Configuration
import ConfigurationTOML

// Create a provider from a TOML file
let provider = try TOMLProvider(filePath: "/path/to/config.toml")
let config = ConfigReader(provider: provider)

// Read configuration values
let title = config.string(forKey: "title")
let port = config.int(forKey: "port", default: 8080)
let debug = config.bool(forKey: "debug", default: false)
```

### Nested Tables

```swift
// config.toml:
// [server]
// host = "localhost"
// port = 8080
//
// [database]
// url = "postgres://localhost/mydb"
// maxConnections = 10

let provider = try TOMLProvider(filePath: "config.toml")
let config = ConfigReader(provider: provider)

let host = config.string(forKey: "server.host")
let port = config.int(forKey: "server.port")
let dbUrl = config.string(forKey: "database.url")
let maxConn = config.int(forKey: "database.maxConnections")
```

### Arrays

```swift
// config.toml:
// ports = [8001, 8002, 8003]
// names = ["alpha", "beta", "gamma"]

let provider = try TOMLProvider(filePath: "config.toml")
let config = ConfigReader(provider: provider)

let ports = config.intArray(forKey: "ports")
let names = config.stringArray(forKey: "names")
```

### Initialization Methods

Create a provider from different sources:

```swift
// From a file path
let provider1 = try TOMLProvider(filePath: "/path/to/config.toml")

// From Data
let data = try Data(contentsOf: url)
let provider2 = try TOMLProvider(data: data)

// From a string
let tomlString = """
title = "My App"
port = 8080
"""
let provider3 = try TOMLProvider(string: tomlString)
```

### Parsing Options (bytes + secrets)

```swift
import Configuration
import ConfigurationTOML

let options = TOMLSnapshot.ParsingOptions(
    bytesDecoder: .hex,
    secretsSpecifier: .dynamic { key, _ in
        key.lowercased().contains("password") || key.lowercased().contains("token")
    }
)

let provider = try TOMLProvider(filePath: "config.toml", parsingOptions: options)
let config = ConfigReader(provider: provider)

let apiKeyBytes = config.bytes(forKey: "api.key")
```

### Using `FileProvider<TOMLSnapshot>`

`TOMLSnapshot` conforms to `FileConfigSnapshot`, so it can be used with Swift Configuration’s file providers:

```swift
import Configuration
import ConfigurationTOML

let provider = try await FileProvider<TOMLSnapshot>(
    filePath: "config.toml",
    parsingOptions: .default
)
let config = ConfigReader(provider: provider)
```

### Complex Configuration

```swift
// config.toml:
// [server]
// host = "localhost"
// port = 8080
//
// [server.ssl]
// enabled = true
// certificate = "/path/to/cert.pem"

let provider = try TOMLProvider(filePath: "config.toml")
let config = ConfigReader(provider: provider)

let host = config.string(forKey: "server.host")
let port = config.int(forKey: "server.port")
let sslEnabled = config.bool(forKey: "server.ssl.enabled")
let cert = config.string(forKey: "server.ssl.certificate")
```

## License

This project is available under the MIT license.
See the LICENSE file for more info.
