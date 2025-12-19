import Testing
@testable import ConfigurationTOML
import Foundation
import ConfigurationTesting
import SystemPackage

private let resourcesPath = FilePath(try! #require(Bundle.module.path(forResource: "Resources", ofType: nil)))
let tomlConfigFile = resourcesPath.appending("config.toml")

struct TOMLProviderTests {
    let provider: TOMLProvider

    init() async throws {
        provider = try await TOMLProvider(filePath: tomlConfigFile)
    }

    @Test func printingDescription() throws {
        let expectedDescription = #"""
            FileProvider<TOMLSnapshot>[20 values]
            """#
        #expect(provider.description == expectedDescription)
    }

    @Test func printingDebugDescription() throws {
        let expectedDebugDescription = #"""
            FileProvider<TOMLSnapshot>[20 values: bool=true, booly.array=true,false, byteChunky.array=bWFnaWM=,bWFnaWMy, bytes=bWFnaWM=, double=3.14, doubly.array=3.14,2.72, int=42, inty.array=42,24, other.bool=false, other.booly.array=false,true,true, other.byteChunky.array=bWFnaWM=,bWFnaWMy,bWFnaWM=, other.bytes=bWFnaWMy, other.double=2.72, other.doubly.array=0.9,1.8, other.int=24, other.inty.array=16,32, other.string=Other Hello, other.stringy.array=Hello,Swift, string=Hello, stringy.array=Hello,World]
            """#
        #expect(provider.debugDescription == expectedDebugDescription)
    }

    @Test func compat() async throws {
        try await ProviderCompatTest(provider: provider).runTest()
    }
}
