import Configuration
import Foundation
import SystemPackage
import TOML

/// A snapshot of configuration values parsed from TOML data.
///
/// This structure represents a point-in-time view of configuration values. It handles the
/// conversion from TOML types to configuration value types.
///
/// ## Usage
///
/// Use with ``FileProvider``:
///
/// ```swift
/// let provider = try await FileProvider<TOMLSnapshot>(filePath: "/etc/config.toml")
/// let config = ConfigReader(provider: provider)
/// ```
public struct TOMLSnapshot {
    /// Errors that can occur when converting a TOML value to a configuration value.
    public enum Error: Swift.Error, Sendable, CustomStringConvertible {
        /// The underlying TOML value can’t be converted to the requested ``ConfigType``.
        case configValueNotConvertible(name: String, type: ConfigType)

        public var description: String {
            switch self {
            case .configValueNotConvertible(let name, let type):
                return "Config value not convertible: \(name) as \(type)"
            }
        }
    }

    /// Parsing options for TOML snapshot creation.
    ///
    /// Use this type to customize how TOML values are converted to configuration values,
    /// including byte decoding and secrets specification.
    public struct ParsingOptions: FileParsingOptions {
        /// A decoder of bytes from a string.
        public var bytesDecoder: any ConfigBytesFromStringDecoder

        /// A specifier for determining which configuration values should be treated as secrets.
        public var secretsSpecifier: SecretsSpecifier<String, any Sendable>

        /// Creates parsing options for TOML snapshots.
        ///
        /// - Parameters:
        ///   - bytesDecoder: The decoder to use for converting string values to byte arrays.
        ///   - secretsSpecifier: The specifier for identifying secret values.
        public init(
            bytesDecoder: some ConfigBytesFromStringDecoder = .base64,
            secretsSpecifier: SecretsSpecifier<String, any Sendable> = .none
        ) {
            self.bytesDecoder = bytesDecoder
            self.secretsSpecifier = secretsSpecifier
        }

        /// The default parsing options.
        ///
        /// Uses base64 byte decoding and treats no values as secrets.
        public static var `default`: Self { .init() }
    }

    private struct ValueWrapper: CustomStringConvertible {
        let value: TOMLValue
        let isSecret: Bool

        var description: String {
            if isSecret { return "<REDACTED>" }
            return value.description
        }
    }

    private static func encodeKeyComponents(_ components: [String]) -> String {
        components.joined(separator: ".")
    }

    private static func encodeKey(_ key: AbsoluteConfigKey) -> String {
        encodeKeyComponents(key.components)
    }

    private static func dataFromRawSpan(_ data: RawSpan) -> Data {
        data.withUnsafeBytes { Data($0) }
    }

    private let values: [String: ValueWrapper]
    public let providerName: String
    private let bytesDecoder: any ConfigBytesFromStringDecoder

    private init(
        values: [String: ValueWrapper],
        providerName: String,
        bytesDecoder: any ConfigBytesFromStringDecoder
    ) {
        self.values = values
        self.providerName = providerName
        self.bytesDecoder = bytesDecoder
    }

    internal init(
        string: String,
        providerName: String,
        parsingOptions: ParsingOptions = .default
    ) throws {
        let decoder = TOMLDecoder()
        let wrapper = try decoder.decode(TOMLTableWrapper.self, from: string)
        let values = Self.flattenValues(wrapper.value, secretsSpecifier: parsingOptions.secretsSpecifier)
        self.init(values: values, providerName: providerName, bytesDecoder: parsingOptions.bytesDecoder)
    }

    private static func flattenValues(
        _ parsedDictionary: [String: TOMLValue],
        secretsSpecifier: SecretsSpecifier<String, any Sendable>
    ) -> [String: ValueWrapper] {
        var values: [String: ValueWrapper] = [:]
        var valuesToIterate: [([String], TOMLValue)] = parsedDictionary.map { ([$0], $1) }
        var index = 0
        while index < valuesToIterate.count {
            let (keyComponents, value) = valuesToIterate[index]
            index += 1
            if case .table(let dict) = value {
                valuesToIterate.append(contentsOf: dict.map { (keyComponents + [$0], $1) })
            } else {
                let encodedKey = encodeKeyComponents(keyComponents)
                let isSecret = secretsSpecifier.isSecret(key: encodedKey, value: value.description)
                values[encodedKey] = .init(value: value, isSecret: isSecret)
            }
        }
        return values
    }

    private func parseValue(
        _ valueWrapper: ValueWrapper,
        key: AbsoluteConfigKey,
        type: ConfigType
    ) throws -> ConfigValue {
        func throwMismatch() throws -> Never {
            throw Error.configValueNotConvertible(name: key.description, type: type)
        }

        let value = valueWrapper.value
        let content: ConfigContent

        func mapArray<T>(_ transform: (TOMLValue) throws -> T) throws -> [T] {
            guard case .array(let array) = value else { try throwMismatch() }
            return try array.map(transform)
        }

        switch type {
        case .string:
            guard let string = value.configStringValue else { try throwMismatch() }
            content = .string(string)
        case .int:
            guard case .integer(let int64) = value else { try throwMismatch() }
            content = .int(Int(int64))
        case .double:
            guard case .float(let double) = value else { try throwMismatch() }
            content = .double(double)
        case .bool:
            guard case .boolean(let bool) = value else { try throwMismatch() }
            content = .bool(bool)
        case .bytes:
            guard case .string(let string) = value, let bytes = bytesDecoder.decode(string) else { try throwMismatch() }
            content = .bytes(bytes)
        case .stringArray:
            let strings = try mapArray { item -> String in
                guard case .string(let str) = item else { try throwMismatch() }
                return str
            }
            content = .stringArray(strings)
        case .intArray:
            let ints = try mapArray { item -> Int in
                guard case .integer(let int64) = item else { try throwMismatch() }
                return Int(int64)
            }
            content = .intArray(ints)
        case .doubleArray:
            let doubles = try mapArray { item -> Double in
                guard case .float(let double) = item else { try throwMismatch() }
                return double
            }
            content = .doubleArray(doubles)
        case .boolArray:
            let bools = try mapArray { item -> Bool in
                guard case .boolean(let bool) = item else { try throwMismatch() }
                return bool
            }
            content = .boolArray(bools)
        case .byteChunkArray:
            let chunks = try mapArray { item -> [UInt8] in
                guard case .string(let str) = item, let bytes = bytesDecoder.decode(str) else { try throwMismatch() }
                return bytes
            }
            content = .byteChunkArray(chunks)
        }

        return ConfigValue(content, isSecret: valueWrapper.isSecret)
    }
}

// MARK: - CustomStringConvertible

extension TOMLSnapshot: CustomStringConvertible {
    public var description: String {
        "\(providerName)[\(values.count) values]"
    }
}

// MARK: - CustomDebugStringConvertible

extension TOMLSnapshot: CustomDebugStringConvertible {
    public var debugDescription: String {
        let prettyValues =
            values
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        return "\(providerName)[\(values.count) values: \(prettyValues)]"
    }
}

// MARK: - ConfigSnapshot

extension TOMLSnapshot: ConfigSnapshot {
    public func value(forKey key: AbsoluteConfigKey, type: ConfigType) throws -> LookupResult {
        let encodedKey = Self.encodeKey(key)
        guard let value = values[encodedKey] else {
            return .init(encodedKey: encodedKey, value: nil)
        }
        return .init(encodedKey: encodedKey, value: try parseValue(value, key: key, type: type))
    }
}

// MARK: - FileConfigSnapshot

extension TOMLSnapshot: FileConfigSnapshot {
    public init(data: RawSpan, providerName: String, parsingOptions: ParsingOptions) throws {
        let fileData = Self.dataFromRawSpan(data)
        guard let string = String(data: fileData, encoding: .utf8) else {
            throw TOMLProviderError.invalidData("Unable to decode data as UTF-8")
        }
        try self.init(string: string, providerName: providerName, parsingOptions: parsingOptions)
    }
}

// MARK: -

/// An enumeration of TOML value types.
enum TOMLValue {
    case string(String)
    case integer(Int64)
    case float(Double)
    case boolean(Bool)
    case offsetDateTime(Date)
    case localDateTime(LocalDateTime)
    case localDate(LocalDate)
    case localTime(LocalTime)
    case array([TOMLValue])
    case table([String: TOMLValue])

    /// TOML allows several date/time literal types; for Configuration we expose those as `.string`.
    fileprivate var configStringValue: String? {
        switch self {
        case .string(let str):
            return str
        case .offsetDateTime, .localDateTime, .localDate, .localTime:
            return description
        default:
            return nil
        }
    }
}

extension TOMLValue: CustomStringConvertible {
    var description: String {
        switch self {
        case .string(let str):
            return str
        case .integer(let int64):
            return int64.description
        case .float(let double):
            return double.description
        case .boolean(let bool):
            return bool.description
        case .offsetDateTime(let date):
            return ISO8601DateFormatter().string(from: date)
        case .localDateTime(let localDateTime):
            return String(
                format: "%04d-%02d-%02dT%02d:%02d:%02d",
                localDateTime.year,
                localDateTime.month,
                localDateTime.day,
                localDateTime.hour,
                localDateTime.minute,
                localDateTime.second
            )
        case .localDate(let localDate):
            return String(
                format: "%04d-%02d-%02d",
                localDate.year,
                localDate.month,
                localDate.day
            )
        case .localTime(let localTime):
            return String(
                format: "%02d:%02d:%02d",
                localTime.hour,
                localTime.minute,
                localTime.second
            )
        case .array(let array):
            if array.isEmpty { return "[]" }
            return array.map(\.description).joined(separator: ",")
        case .table:
            return "{...}"
        }
    }
}

/// Wrapper for decoding a TOML document into a dictionary.
private struct TOMLTableWrapper: Decodable {
    let value: [String: TOMLValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var result: [String: TOMLValue] = [:]
        for key in container.allKeys {
            result[key.stringValue] = try container.decode(TOMLValueWrapper.self, forKey: key).value
        }
        self.value = result
    }
}

/// Wrapper for decoding individual TOML values.
private struct TOMLValueWrapper: Decodable {
    let value: TOMLValue

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            throw TOMLProviderError.invalidData("Unexpected nil value")
        }

        if let dict = try? container.decode([String: TOMLValueWrapper].self) {
            var result: [String: TOMLValue] = [:]
            for (key, wrapper) in dict {
                result[key] = wrapper.value
            }
            self.value = .table(result)
        } else if let array = try? container.decode([TOMLValueWrapper].self) {
            self.value = .array(array.map(\.value))
        } else if let string = try? container.decode(String.self) {
            self.value = .string(string)
        } else if let int = try? container.decode(Int64.self) {
            self.value = .integer(int)
        } else if let double = try? container.decode(Double.self) {
            self.value = .float(double)
        } else if let bool = try? container.decode(Bool.self) {
            self.value = .boolean(bool)
        } else if let date = try? container.decode(Date.self) {
            self.value = .offsetDateTime(date)
        } else {
            throw TOMLProviderError.invalidData("Unable to decode TOML value")
        }
    }
}

/// A coding key that accepts any string value.
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
