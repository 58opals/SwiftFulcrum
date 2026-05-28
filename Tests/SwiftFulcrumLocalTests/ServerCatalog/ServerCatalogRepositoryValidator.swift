// ServerCatalogRepositoryValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ServerCatalogRepositoryValidator {
    @Test("Loads bundled catalogs when available")
    func loadBundledCatalogs() async throws {
        let networks: [SwiftFulcrum.Client.Configuration.Network] = [.mainnet, .testnet, .chipnet]

        for network in networks {
            let servers = try await SwiftFulcrum.ServerCatalog.Repository.bundled.loadServers(
                for: network,
                fallback: .init()
            )

            #expect(!servers.isEmpty)
            #expect(servers.allSatisfy { ["ws", "wss"].contains($0.scheme?.lowercased()) })
        }
    }

    @Test("Testnet bundled catalog excludes chipnet servers")
    func testnetBundledCatalogExcludesChipnetServers() async throws {
        let testnetServers = try await SwiftFulcrum.ServerCatalog.Repository.bundled.loadServers(
            for: .testnet,
            fallback: .init()
        )
        let chipnetServers = try await SwiftFulcrum.ServerCatalog.Repository.bundled.loadServers(
            for: .chipnet,
            fallback: .init()
        )

        #expect(testnetServers.allSatisfy { $0.host != "chipnet.imaginary.cash" })
        #expect(chipnetServers.contains { $0.host == "chipnet.imaginary.cash" })
    }

    @Test(
        "Rejects malformed string catalog URLs",
        arguments: [
            #""wss:missing-host.example""#,
            #""wss://%20""#,
            #""wss://fulcrum.example:0""#,
            #""wss://user:pass@fulcrum.example""#
        ]
    )
    func rejectMalformedStringCatalogURLs(_ json: String) throws {
        let data = Data(json.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONRPCCodec.Coder.decoder.decode(WebSocketConnection.Server.self, from: data)
        }
    }

    @Test(
        "Rejects object catalog URLs with invalid ports",
        arguments: [-1, 0, 65_536]
    )
    func rejectObjectCatalogURLsWithInvalidPorts(_ port: Int) throws {
        let data = Data(#"{"host":"fulcrum.example","port":\#(port)}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONRPCCodec.Coder.decoder.decode(WebSocketConnection.Server.self, from: data)
        }
    }

    @Test(
        "Normalizes catalog URLs with surrounding whitespace",
        arguments: [
            #"{"host":"fulcrum.example","scheme":" WSS "}"#,
            #""  wss://fulcrum.example  ""#
        ]
    )
    func normalizeCatalogURLWhitespace(_ json: String) throws {
        let data = Data(json.utf8)

        let server = try JSONRPCCodec.Coder.decoder.decode(WebSocketConnection.Server.self, from: data)

        #expect(server.url.absoluteString == "wss://fulcrum.example")
    }

    @Test("Falls back when bundled catalog is unavailable")
    func loadFallbackBootstrapList() async throws {
        let fallbackServers = [URL(string: "wss://fallback.fulcrum.example")!]
        let fallbackLoader = FallbackLoader()
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            try await fallbackLoader.load(fallback)
        }

        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)

        #expect(servers == fallbackServers)
    }

    @Test("Sanitizes fallback catalog entries")
    func sanitizeFallbackCatalog() async throws {
        let fallbackServers = [
            URL(string: "http://invalid.fulcrum.example")!,
            URL(string: "ws:///missing-host")!,
            URL(string: "wss://%20")!,
            URL(string: "wss://valid.fulcrum.example")!
        ]
        let fallbackLoader = FallbackLoader()
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            try await fallbackLoader.load(fallback)
        }

        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)

        #expect(servers.count == 1)
        #expect(servers.first?.absoluteString == "wss://valid.fulcrum.example")
    }
    
    @Test("Constant catalog filters invalid catalog entries")
    func constantCatalogFiltersInvalidEntries() async throws {
        let validServerOne = URL(string: "wss://valid-one.fulcrum.example")!
        let validServerTwo = URL(string: "ws://valid-two.fulcrum.example")!
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            validServerOne,
            URL(string: "ftp://invalid-two.fulcrum.example")!,
            validServerTwo
        ])
        
        let servers = try await loader.loadServers(for: .mainnet, fallback: .init())
        
        #expect(servers == [validServerOne, validServerTwo])
    }
    
    @Test("Constant catalog throws when all entries are invalid")
    func constantCatalogThrowsWhenAllEntriesAreInvalid() async {
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            URL(string: "ftp://invalid.fulcrum.example")!
        ])
        
        await #expect(throws: SwiftFulcrum.Client.Error.transport(.setupFailed)) {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
        }
    }

    @Test("Throws when both bundled and fallback catalogs are empty")
    func throwWhenCatalogCannotBeBuilt() async {
        let fallbackLoader = FallbackLoader()
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, _ in
            try await fallbackLoader.load(.init())
        }

        await #expect(throws: SwiftFulcrum.Client.Error.transport(.setupFailed)) {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
        }
    }

    @Test("Uses constant catalog during SwiftFulcrum.Client initialization after filtering invalid entries")
    func useConstantCatalogLoader() async throws {
        let expectedServer = URL(string: "wss://injected.fulcrum.example")!
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            expectedServer,
            URL(string: "ftp://invalid-two.fulcrum.example")!
        ])
        let configuration = SwiftFulcrum.Client.Configuration(serverCatalogLoader: loader)

        let clientInterface = try await SwiftFulcrum.Client(configuration: configuration)
        let client = await clientInterface.client
        let transport = await client.transport
        let endpoint = await transport.endpoint

        #expect(endpoint == expectedServer)
    }

    @Test("Client initialization rejects endpoints with invalid ports")
    func clientInitializationRejectsEndpointsWithInvalidPorts() async throws {
        let endpoint = try #require(URL(string: "wss://invalid-port.fulcrum.example:0"))

        await #expect(throws: SwiftFulcrum.Client.Error.self) {
            _ = try await SwiftFulcrum.Client(connectingTo: endpoint)
        }
    }

    @Test("Client initialization ignores invalid custom catalog entries when a valid endpoint exists")
    func clientInitializationIgnoresInvalidCustomCatalogEntries() async throws {
        let expectedServer = URL(string: "wss://valid.fulcrum.example")!
        let invalidServers = (0 ..< 32).map { index in
            URL(string: "http://invalid-\(index).fulcrum.example")!
        }
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, _ in
            invalidServers + [expectedServer]
        }
        let configuration = SwiftFulcrum.Client.Configuration(serverCatalogLoader: loader)

        for attempt in 0 ..< 8 {
            do {
                let clientInterface = try await SwiftFulcrum.Client(configuration: configuration)
                let client = await clientInterface.client
                let transport = await client.transport
                let endpoint = await transport.endpoint

                #expect(endpoint == expectedServer)
                await clientInterface.stop()
            } catch {
                Issue.record(
                    "Attempt \(attempt) should have selected the valid endpoint instead of failing: \(error)"
                )
                return
            }
        }
    }
}
