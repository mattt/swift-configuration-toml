import Configuration
import Foundation

/// A configuration provider that reads values from TOML files.
///
/// Use `TOMLProvider` to load configuration from TOML-formatted data.
/// The provider supports nested keys using dot notation, which maps directly
/// to TOML table hierarchies.
///
/// ## Creating a Provider
///
/// Create a provider from a file path, raw data, or a string:
///
/// ```swift
/// // From a file
/// let provider = try TOMLProvider(filePath: "/path/to/config.toml")
///
/// // From data
/// let provider = try TOMLProvider(data: tomlData)
///
/// // From a string
/// let provider = try TOMLProvider(string: """
///     [http]
///     timeout = 60
///     """)
/// ```
///
/// ## Reading Configuration Values
///
/// Access values using a ``ConfigReader``:
///
/// ```swift
/// let config = ConfigReader(provider: provider)
/// let timeout = config.int(forKey: "http.timeout", default: 60)
/// ```
///
/// ## Supported Types
///
/// The provider maps TOML types to configuration types:
///
/// | TOML Type | Configuration Type |
/// |-----------|-------------------|
/// | String | `.string` |
/// | Integer | `.int` |
/// | Float | `.double` |
/// | Boolean | `.bool` |
/// | Array of strings | `.stringArray` |
/// | Array of integers | `.intArray` |
/// | Array of floats | `.doubleArray` |
/// | Array of booleans | `.boolArray` |
/// | Date/time types | `.string` (ISO 8601) |
public struct TOMLProvider: ConfigProvider {
    private let storedSnapshot: TOMLSnapshot

    /// Creates a provider by loading a TOML file from the specified path.
    ///
    /// - Parameter filePath: The path to the TOML file.
    /// - Throws: ``TOMLProviderError/invalidData(_:)`` if the file contents
    ///   cannot be read or parsed as valid TOML.
    public init(filePath: String, parsingOptions: TOMLSnapshot.ParsingOptions = .default) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        try self.init(data: data, parsingOptions: parsingOptions)
    }

    /// Creates a provider from TOML-encoded data.
    ///
    /// - Parameter data: UTF-8 encoded TOML data.
    /// - Throws: ``TOMLProviderError/invalidData(_:)`` if the data is not
    ///   valid UTF-8 or cannot be parsed as TOML.
    public init(data: Data, parsingOptions: TOMLSnapshot.ParsingOptions = .default) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw TOMLProviderError.invalidData("Unable to decode data as UTF-8")
        }
        try self.init(string: string, parsingOptions: parsingOptions)
    }

    /// Creates a provider from a TOML-formatted string.
    ///
    /// - Parameter string: A TOML-formatted string.
    /// - Throws: ``TOMLProviderError/invalidData(_:)`` if the string
    ///   cannot be parsed as valid TOML.
    public init(string: String, parsingOptions: TOMLSnapshot.ParsingOptions = .default) throws {
        self.storedSnapshot = try TOMLSnapshot(
            string: string,
            providerName: "TOMLProvider",
            parsingOptions: parsingOptions
        )
    }

    public var providerName: String { "TOMLProvider" }

    public func value(forKey key: AbsoluteConfigKey, type: ConfigType) throws -> LookupResult {
        try storedSnapshot.value(forKey: key, type: type)
    }

    public func fetchValue(forKey key: AbsoluteConfigKey, type: ConfigType) async throws -> LookupResult {
        try value(forKey: key, type: type)
    }

    public func watchValue<Return: ~Copyable>(
        forKey key: AbsoluteConfigKey,
        type: ConfigType,
        updatesHandler:
            nonisolated(nonsending)(
                _ updates: ConfigUpdatesAsyncSequence<Result<LookupResult, any Error>, Never>
            ) async throws -> Return
    ) async throws -> Return {
        try await watchValueFromValue(forKey: key, type: type, updatesHandler: updatesHandler)
    }

    public func snapshot() -> any ConfigSnapshot {
        storedSnapshot
    }

    public func watchSnapshot<Return: ~Copyable>(
        updatesHandler:
            nonisolated(nonsending)(
                _ updates: ConfigUpdatesAsyncSequence<any ConfigSnapshot, Never>
            ) async throws -> Return
    ) async throws -> Return {
        try await watchSnapshotFromSnapshot(updatesHandler: updatesHandler)
    }
}

// MARK: - Errors

/// Errors that can occur when creating or using a TOML provider.
public enum TOMLProviderError: Error, Sendable {
    /// The provided data is invalid.
    ///
    /// - Parameter message: A description of what was invalid.
    case invalidData(_ message: String)
}
