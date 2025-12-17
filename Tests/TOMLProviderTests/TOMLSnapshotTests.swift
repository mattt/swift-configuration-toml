import Configuration
import ConfigurationTesting
import Foundation
import Testing

@testable import TOMLProvider

let tomlTestFileContents = """
    string = "Hello"
    int = 42
    double = 3.14
    bool = true
    bytes = "bWFnaWM="

    [other]
    string = "Other Hello"
    int = 24
    double = 2.72
    bool = false
    bytes = "bWFnaWMy"

        [other.stringy]
        array = ["Hello", "Swift"]

        [other.inty]
        array = [16, 32]

        [other.doubly]
        array = [0.9, 1.8]

        [other.booly]
        array = [false, true, true]

        [other.byteChunky]
        array = ["bWFnaWM=", "bWFnaWMy", "bWFnaWM="]

    [stringy]
    array = ["Hello", "World"]

    [inty]
    array = [42, 24]

    [doubly]
    array = [3.14, 2.72]

    [booly]
    array = [true, false]

    [byteChunky]
    array = ["bWFnaWM=", "bWFnaWMy"]

    """

@Suite("TOMLProvider Compatibility Tests")
struct TOMLProviderCompatibilityTests {

    @Test("Provider compatibility with standard test data (excluding bytes types)")
    func compat() async throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)

        let config = ConfigReader(provider: provider)
        #expect(config.string(forKey: "string") == "Hello")
        #expect(config.string(forKey: "other.string") == "Other Hello")
        #expect(config.int(forKey: "int") == 42)
        #expect(config.int(forKey: "other.int") == 24)
        #expect(config.double(forKey: "double") == 3.14)
        #expect(config.double(forKey: "other.double") == 2.72)
        #expect(config.bool(forKey: "bool") == true)
        #expect(config.bool(forKey: "other.bool") == false)
        #expect(config.stringArray(forKey: "stringy.array") == ["Hello", "World"])
        #expect(config.stringArray(forKey: "other.stringy.array") == ["Hello", "Swift"])
        #expect(config.intArray(forKey: "inty.array") == [42, 24])
        #expect(config.intArray(forKey: "other.inty.array") == [16, 32])
        #expect(config.doubleArray(forKey: "doubly.array") == [3.14, 2.72])
        #expect(config.doubleArray(forKey: "other.doubly.array") == [0.9, 1.8])
        #expect(config.boolArray(forKey: "booly.array") == [true, false])
        #expect(config.boolArray(forKey: "other.booly.array") == [false, true, true])
    }
}

@Suite("TOMLProvider Value Retrieval Tests")
struct TOMLProviderValueRetrievalTests {

    @Test("String value retrieval")
    func stringValue() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "string") == "Hello")
        #expect(config.string(forKey: "other.string") == "Other Hello")
    }

    @Test("Int value retrieval")
    func intValue() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "int") == 42)
        #expect(config.int(forKey: "other.int") == 24)
    }

    @Test("Double value retrieval")
    func doubleValue() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.double(forKey: "double") == 3.14)
        #expect(config.double(forKey: "other.double") == 2.72)
    }

    @Test("Bool value retrieval")
    func boolValue() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.bool(forKey: "bool") == true)
        #expect(config.bool(forKey: "other.bool") == false)
    }

    @Test("String array retrieval")
    func stringArray() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.stringArray(forKey: "stringy.array") == ["Hello", "World"])
        #expect(config.stringArray(forKey: "other.stringy.array") == ["Hello", "Swift"])
    }

    @Test("Int array retrieval")
    func intArray() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.intArray(forKey: "inty.array") == [42, 24])
        #expect(config.intArray(forKey: "other.inty.array") == [16, 32])
    }

    @Test("Double array retrieval")
    func doubleArray() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.doubleArray(forKey: "doubly.array") == [3.14, 2.72])
        #expect(config.doubleArray(forKey: "other.doubly.array") == [0.9, 1.8])
    }

    @Test("Bool array retrieval")
    func boolArray() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.boolArray(forKey: "booly.array") == [true, false])
        #expect(config.boolArray(forKey: "other.booly.array") == [false, true, true])
    }

    @Test("Missing key returns nil")
    func missingKey() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "nonexistent") == nil)
        #expect(config.string(forKey: "absent.string") == nil)
        #expect(config.int(forKey: "absent.int") == nil)
        #expect(config.double(forKey: "absent.double") == nil)
        #expect(config.bool(forKey: "absent.bool") == nil)
    }

    @Test("Default values for missing keys")
    func defaultValues() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "missing", default: "default") == "default")
        #expect(config.int(forKey: "missing", default: 99) == 99)
        #expect(config.double(forKey: "missing", default: 1.5) == 1.5)
        #expect(config.bool(forKey: "missing", default: true) == true)
    }
}

@Suite("TOMLProvider Type Conversion Tests")
struct TOMLProviderTypeConversionTests {

    @Test("Type mismatch returns nil")
    func typeMismatch() throws {
        let toml = """
            string = "hello"
            number = 42
            flag = true
            ratio = 3.14
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "string") == nil)
        #expect(config.string(forKey: "number") == nil)
        #expect(config.double(forKey: "flag") == nil)
        #expect(config.bool(forKey: "ratio") == nil)
    }

    @Test("Mixed array type returns nil")
    func mixedArrayType() throws {
        let toml = """
            mixed = [1, "two", 3]
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.intArray(forKey: "mixed") == nil)
        #expect(config.stringArray(forKey: "mixed") == nil)
    }

    @Test("Empty array")
    func emptyArray() throws {
        let toml = """
            empty = []
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.stringArray(forKey: "empty") == [])
        #expect(config.intArray(forKey: "empty") == [])
    }
}

@Suite("TOMLProvider Date/Time Tests")
struct TOMLProviderDateTimeTests {

    @Test("Offset datetime as ISO8601 string")
    func offsetDateTime() throws {
        let toml = """
            datetime = 2024-12-25T14:30:00Z
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        let result = config.string(forKey: "datetime")
        #expect(result != nil)
        #expect(result?.contains("2024-12-25") == true)
        #expect(result?.contains("14:30:00") == true)
    }

    @Test("Offset datetime with timezone")
    func offsetDateTimeWithTimezone() throws {
        let toml = """
            datetime = 2024-12-25T14:30:00+05:00
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        let result = config.string(forKey: "datetime")
        #expect(result != nil)
        #expect(result?.contains("2024") == true)
    }
}

@Suite("TOMLProvider Nested Structure Tests")
struct TOMLProviderNestedStructureTests {

    @Test("Deeply nested keys")
    func deeplyNestedKeys() throws {
        let toml = """
            [level1]
            value = 1
            [level1.level2]
            value = 2
            [level1.level2.level3]
            value = 3
            [level1.level2.level3.level4]
            value = 4
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "level1.value") == 1)
        #expect(config.int(forKey: "level1.level2.value") == 2)
        #expect(config.int(forKey: "level1.level2.level3.value") == 3)
        #expect(config.int(forKey: "level1.level2.level3.level4.value") == 4)
    }

    @Test("Dotted keys (inline)")
    func dottedKeys() throws {
        let toml = """
            fruit.apple.color = "red"
            fruit.apple.taste = "sweet"
            fruit.banana.color = "yellow"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "fruit.apple.color") == "red")
        #expect(config.string(forKey: "fruit.apple.taste") == "sweet")
        #expect(config.string(forKey: "fruit.banana.color") == "yellow")
    }

    @Test("Array of tables")
    func arrayOfTables() throws {
        let toml = """
            [[products]]
            name = "Hammer"
            price = 9.99

            [[products]]
            name = "Nail"
            price = 0.05
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "products.0.name") == nil)
    }
}

@Suite("TOMLProvider Initialization Tests")
struct TOMLProviderInitializationTests {

    @Test("Provider name")
    func providerName() throws {
        let provider = try TOMLProvider(string: "key = 'value'")
        #expect(provider.providerName == "TOMLProvider")
    }

    @Test("Init from data")
    func initFromData() throws {
        let toml = """
            title = "From Data"
            """
        let data = toml.data(using: .utf8)!
        let provider = try TOMLProvider(data: data)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "title") == "From Data")
    }

    @Test("Invalid TOML throws error")
    func invalidTOMLThrows() {
        let invalidTOML = """
            key = "unclosed string
            """

        #expect(throws: Error.self) {
            _ = try TOMLProvider(string: invalidTOML)
        }
    }

    @Test("Invalid UTF-8 data throws error")
    func invalidUTF8Throws() {
        let invalidData = Data([0xFF, 0xFE])

        #expect(throws: TOMLProviderError.self) {
            _ = try TOMLProvider(data: invalidData)
        }
    }

    @Test("Empty string creates empty provider")
    func emptyString() throws {
        let provider = try TOMLProvider(string: "")
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "any") == nil)
    }
}

@Suite("TOMLProvider Async Tests")
struct TOMLProviderAsyncTests {

    @Test("Snapshot retrieval")
    func snapshotRetrieval() throws {
        let provider = try TOMLProvider(string: tomlTestFileContents)
        let snapshot = provider.snapshot()

        #expect(snapshot.providerName == "TOMLProvider")
    }
}

@Suite("TOMLProvider TOML-Specific Features Tests")
struct TOMLProviderFeatureTests {

    @Test("Inline tables")
    func inlineTables() throws {
        let toml = """
            name = { first = "Tom", last = "Preston-Werner" }
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "name.first") == "Tom")
        #expect(config.string(forKey: "name.last") == "Preston-Werner")
    }

    @Test("Multiline basic strings")
    func multilineStrings() throws {
        let toml = """
            str = \"\"\"
            Roses are red
            Violets are blue\"\"\"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        let result = config.string(forKey: "str")
        #expect(result != nil)
        #expect(result?.contains("Roses") == true)
    }

    @Test("Literal strings")
    func literalStrings() throws {
        let toml = """
            path = 'C:\\Users\\nodejs\\templates'
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "path") == "C:\\Users\\nodejs\\templates")
    }

    @Test("Hexadecimal integers")
    func hexIntegers() throws {
        let toml = """
            hex = 0xDEADBEEF
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "hex") == 0xDEADBEEF)
    }

    @Test("Octal integers")
    func octalIntegers() throws {
        let toml = """
            oct = 0o755
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "oct") == 0o755)
    }

    @Test("Binary integers")
    func binaryIntegers() throws {
        let toml = """
            bin = 0b11010110
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "bin") == 0b11010110)
    }

    @Test("Special float values")
    func specialFloats() throws {
        let toml = """
            pos_inf = inf
            neg_inf = -inf
            nan_value = nan
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.double(forKey: "pos_inf") == .infinity)
        #expect(config.double(forKey: "neg_inf") == -.infinity)
        #expect(config.double(forKey: "nan_value")?.isNaN == true)
    }

    @Test("Underscores in numbers")
    func underscoresInNumbers() throws {
        let toml = """
            large = 1_000_000
            precise = 3.141_592_653
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "large") == 1_000_000)
        #expect(config.double(forKey: "precise") == 3.141592653)
    }

    @Test("Super table with sub-tables")
    func superTables() throws {
        let toml = """
            [fruit.apple]
            color = "red"

            [fruit.apple.texture]
            smooth = true

            [fruit.orange]
            color = "orange"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "fruit.apple.color") == "red")
        #expect(config.bool(forKey: "fruit.apple.texture.smooth") == true)
        #expect(config.string(forKey: "fruit.orange.color") == "orange")
    }
}

@Suite("TOMLProvider Edge Cases Tests")
struct TOMLProviderEdgeCaseTests {

    @Test("Unicode strings")
    func unicodeStrings() throws {
        let toml = """
            emoji = "🎉"
            chinese = "中文"
            escaped = "\\u0041"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "emoji") == "🎉")
        #expect(config.string(forKey: "chinese") == "中文")
        #expect(config.string(forKey: "escaped") == "A")
    }

    @Test("Quoted keys with spaces")
    func quotedKeysWithSpaces() throws {
        let toml = """
            "character encoding" = "UTF-8"
            "site name" = "My Site"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "character encoding") == "UTF-8")
        #expect(config.string(forKey: "site name") == "My Site")
    }

    @Test("Negative numbers")
    func negativeNumbers() throws {
        let toml = """
            neg_int = -42
            neg_float = -3.14
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "neg_int") == -42)
        #expect(config.double(forKey: "neg_float") == -3.14)
    }

    @Test("Zero values")
    func zeroValues() throws {
        let toml = """
            zero_int = 0
            zero_float = 0.0
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.int(forKey: "zero_int") == 0)
        #expect(config.double(forKey: "zero_float") == 0.0)
    }

    @Test("Empty strings")
    func emptyStrings() throws {
        let toml = """
            empty = ""
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "empty") == "")
    }

    @Test("Comments are ignored")
    func commentsIgnored() throws {
        let toml = """
            # This is a comment
            key = "value" # inline comment
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "key") == "value")
    }

    @Test("Case sensitivity")
    func caseSensitivity() throws {
        let toml = """
            Key = "upper"
            key = "lower"
            KEY = "all caps"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        #expect(config.string(forKey: "Key") == "upper")
        #expect(config.string(forKey: "key") == "lower")
        #expect(config.string(forKey: "KEY") == "all caps")
    }
}
