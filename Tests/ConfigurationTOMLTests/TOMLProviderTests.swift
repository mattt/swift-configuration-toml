import Foundation
import Testing
import Configuration
import ConfigurationTesting
import SystemPackage

@testable import ConfigurationTOML

private let resourcesPath = FilePath(try! #require(Bundle.module.path(forResource: "Resources", ofType: nil)))
let tomlConfigFile = resourcesPath.appending("config.toml")

@Suite("TOMLProvider Tests")
struct TOMLProviderTests {
    let provider: TOMLProvider

    init() async throws {
        provider = try await TOMLProvider(filePath: tomlConfigFile)
    }

    @Test func printingDescription() throws {
        let expectedDescription = #"""
            FileProvider<TOMLSnapshot>[24 values]
            """#
        #expect(provider.description == expectedDescription)
    }

    @Test func printingDebugDescription() throws {
        let expectedDebugDescription = #"""
            FileProvider<TOMLSnapshot>[24 values: bool=true, booly.array=true,false, byteChunky.array=bWFnaWM=,bWFnaWMy, bytes=bWFnaWM=, double=3.14, doubly.array=3.14,2.72, int=42, inty.array=42,24, local_date=2024-01-02, local_datetime=2024-01-02T03:04:05, local_time=03:04:05, offset_datetime=2024-01-02T03:04:05Z, other.bool=false, other.booly.array=false,true,true, other.byteChunky.array=bWFnaWM=,bWFnaWMy,bWFnaWM=, other.bytes=bWFnaWMy, other.double=2.72, other.doubly.array=0.9,1.8, other.int=24, other.inty.array=16,32, other.string=Other Hello, other.stringy.array=Hello,Swift, string=Hello, stringy.array=Hello,World]
            """#
        #expect(provider.debugDescription == expectedDebugDescription)
    }

    @Test func compat() async throws {
        try await ProviderCompatTest(provider: provider).runTest()
    }

    @Test func dateTimeLiteralsAsStrings() throws {
        let config = ConfigReader(provider: provider)

        let offsetDateTime = config.string(forKey: "offset_datetime")
        #expect(offsetDateTime != nil)
        #expect(offsetDateTime?.contains("2024-01-02") == true)

        let localDateTime = config.string(forKey: "local_datetime")
        #expect(localDateTime == "2024-01-02T03:04:05")

        let localDate = config.string(forKey: "local_date")
        #expect(localDate == "2024-01-02")

        let localTime = config.string(forKey: "local_time")
        #expect(localTime == "03:04:05")
    }
}

#if Reloading
    @Suite("ReloadingTOMLProvider Tests")
    struct ReloadingTOMLProviderTests {
        @Test func typealiasIsDefined() {
            let _: ReloadingTOMLProvider.Type = ReloadingTOMLProvider.self
            #expect(ReloadingTOMLProvider.self == ReloadingFileProvider<TOMLSnapshot>.self)
        }
    }
#endif
