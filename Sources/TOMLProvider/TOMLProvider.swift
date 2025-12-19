import Configuration
import Foundation

/// A configuration provider that reads values from TOML data.
///
/// Use `TOMLProvider` with `ConfigReader` to read configuration values from TOML-formatted
/// data. Nested keys use dot notation, which maps directly to TOML table hierarchies.
///
/// ## Usage
///
/// Create a provider from a TOML file:
///
/// ```swift
/// let provider = try await TOMLProvider(filePath: "/etc/config.toml")
/// let config = ConfigReader(provider: provider)
/// ```
///
/// ## Supported types
///
/// This provider supports the following `ConfigType` values:
/// - `.string`
/// - `.int`
/// - `.double`
/// - `.bool`
/// - `.bytes`
/// - `.stringArray`
/// - `.intArray`
/// - `.doubleArray`
/// - `.boolArray`
/// - `.byteChunkArray`
///
/// TOML date and time literals are represented as `.string` values.
public typealias TOMLProvider = FileProvider<TOMLSnapshot>

/// Errors that can occur when creating or using a TOML provider.
public enum TOMLProviderError: Error, Sendable {
    /// The provided data is invalid.
    ///
    /// - Parameter message: A description of what was invalid.
    case invalidData(_ message: String)
}
