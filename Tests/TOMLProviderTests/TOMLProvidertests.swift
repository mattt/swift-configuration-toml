import Configuration
import Testing

@testable import TOMLProvider

@Suite("TOMLProvider Tests")
struct TOMLProviderTests {

    @Test("Basic string value retrieval")
    func testBasicStringValue() throws {
        let toml = """
            title = "My App"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let title = config.string(forKey: "title")

        #expect(title == "My App")
    }

    @Test("Basic integer value retrieval")
    func testBasicIntegerValue() throws {
        let toml = """
            port = 8080
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let port = config.int(forKey: "port")

        #expect(port == 8080)
    }

    @Test("Basic boolean value retrieval")
    func testBasicBooleanValue() throws {
        let toml = """
            debug = true
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let debug = config.bool(forKey: "debug")

        #expect(debug == true)
    }

    @Test("Basic double value retrieval")
    func testBasicDoubleValue() throws {
        let toml = """
            ratio = 3.14
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let ratio = config.double(forKey: "ratio")

        #expect(ratio == 3.14)
    }

    @Test("Nested key access")
    func testNestedKeyAccess() throws {
        let toml = """
            [http]
            timeout = 30
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let timeout = config.int(forKey: "http.timeout")

        #expect(timeout == 30)
    }

    @Test("Deeply nested key access")
    func testDeeplyNestedKeyAccess() throws {
        let toml = """
            [database]
            [database.connection]
            timeout = 60
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let timeout = config.int(forKey: "database.connection.timeout")

        #expect(timeout == 60)
    }

    @Test("Array value retrieval")
    func testArrayValue() throws {
        let toml = """
            ports = [8001, 8002, 8003]
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let ports = config.intArray(forKey: "ports")

        #expect(ports != nil)
        #expect(ports?.count == 3)
        #expect(ports?[0] == 8001)
        #expect(ports?[1] == 8002)
        #expect(ports?[2] == 8003)
    }

    @Test("String array value retrieval")
    func testStringArrayValue() throws {
        let toml = """
            names = ["alpha", "beta", "gamma"]
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let names = config.stringArray(forKey: "names")

        #expect(names != nil)
        #expect(names?.count == 3)
        #expect(names?[0] == "alpha")
        #expect(names?[1] == "beta")
        #expect(names?[2] == "gamma")
    }

    @Test("Missing key returns nil")
    func testMissingKey() throws {
        let toml = """
            title = "My App"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let missing = config.string(forKey: "nonexistent")

        #expect(missing == nil)
    }

    @Test("Default value when key is missing")
    func testDefaultValue() throws {
        let toml = """
            title = "My App"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)
        let timeout = config.int(forKey: "http.timeout", default: 60)

        #expect(timeout == 60)
    }

    @Test("Complex nested structure")
    func testComplexNestedStructure() throws {
        let toml = """
            [server]
            host = "localhost"
            port = 8080

            [server.ssl]
            enabled = true
            certificate = "/path/to/cert.pem"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        let host = config.string(forKey: "server.host")
        let port = config.int(forKey: "server.port")
        let sslEnabled = config.bool(forKey: "server.ssl.enabled")
        let certificate = config.string(forKey: "server.ssl.certificate")

        #expect(host == "localhost")
        #expect(port == 8080)
        #expect(sslEnabled == true)
        #expect(certificate == "/path/to/cert.pem")
    }

    @Test("Invalid TOML throws error")
    func testInvalidTOML() {
        let invalidTOML = """
            title = "unclosed string
            """

        #expect(throws: Error.self) {
            _ = try TOMLProvider(string: invalidTOML)
        }
    }

    @Test("Initialization from data")
    func testInitializationFromData() throws {
        let toml = """
            title = "My App"
            port = 8080
            """

        let data = toml.data(using: .utf8)!
        let provider = try TOMLProvider(data: data)
        let config = ConfigReader(provider: provider)

        let title = config.string(forKey: "title")
        let port = config.int(forKey: "port")

        #expect(title == "My App")
        #expect(port == 8080)
    }

    @Test("Dotted keys in TOML")
    func testDottedKeys() throws {
        let toml = """
            fruit.apple.color = "red"
            fruit.apple.taste = "sweet"
            """

        let provider = try TOMLProvider(string: toml)
        let config = ConfigReader(provider: provider)

        let color = config.string(forKey: "fruit.apple.color")
        let taste = config.string(forKey: "fruit.apple.taste")

        #expect(color == "red")
        #expect(taste == "sweet")
    }
}
