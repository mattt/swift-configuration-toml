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
public typealias TOMLProvider = FileProvider<TOMLSnapshot>

/// Errors that can occur when creating or using a TOML provider.
public enum TOMLProviderError: Error, Sendable {
    /// The provided data is invalid.
    ///
    /// - Parameter message: A description of what was invalid.
    case invalidData(_ message: String)
}
