// ServerCatalogRepositoryValidator~Bundled.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
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
            #""wss://user:pass@fulcrum.example""#,
            #""wss://fulcrum.example#fragment""#
        ]
    )
    func rejectMalformedStringCatalogURLs(_ json: String) throws {
        expectServerCatalogEntryDecodeFailure(json)
    }

    @Test(
        "Rejects object catalog entries with invalid ports",
        arguments: [-1, 0, 65_536]
    )
    func rejectObjectCatalogEntriesWithInvalidPorts(_ port: Int) throws {
        expectServerCatalogEntryDecodeFailure(#"{"host":"fulcrum.example","port":\#(port)}"#)
    }

    @Test(
        "Rejects object catalog hosts with user info delimiters",
        arguments: [
            "user@fulcrum.example",
            "user:pass@fulcrum.example"
        ]
    )
    func rejectObjectCatalogHostsWithUserInfoDelimiters(_ host: String) throws {
        expectServerCatalogEntryDecodeFailure(#"{"host":"\#(host)"}"#)
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
}
