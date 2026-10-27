// ServerCatalogRepositoryValidator~Bundled.swift

import CryptoKit
import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
    @Test(
        "Reviewed catalog bytes and ordered peers require an explicit snapshot update",
        arguments: [SwiftFulcrum.Client.Configuration.Network.mainnet, .testnet, .chipnet]
    )
    func reviewedCatalogSnapshot(_ network: SwiftFulcrum.Client.Configuration.Network) async throws {
        let expectedDigest: String
        let expectedURLs: [String]
        switch network {
        case .mainnet:
            expectedDigest = "57bed7a91c4b5fa8feb26a9e149735a928cdedbc5c74ebafc8f7dab257f52f59"
            expectedURLs = [
                "wss://bch.imaginary.cash:50004",
                "wss://fulcrum.greyh.at:50004",
                "wss://cashnode.bch.ninja:50004",
                "wss://fulcrum.fountainhead.cash:50002",
                "wss://electrum.imaginary.cash:50004",
                "wss://electroncash.dk:50004",
                "wss://bch.loping.net:50004",
                "wss://fulcrum.jettscythe.xyz:50004"
            ]
        case .testnet:
            expectedDigest = "e5e46e61f09c20b3149e498a2ac0d15ad36eb7beee10b93f2263b24d0613b759"
            expectedURLs = ["wss://testnet.imaginary.cash:50004", "wss://testnet.bch.loping.net:51004"]
        case .chipnet:
            expectedDigest = "a8096798611a0814db629a4b5d0e0e25d5b73540feb7b10945ffcb7fc88cd524"
            expectedURLs = ["wss://chipnet.imaginary.cash:50004"]
        }
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = root.appendingPathComponent("Sources/SwiftFulcrum/Network/WebSocket/\(network.resourceName).json")
        let digest = SHA256.hash(data: try Data(contentsOf: source))
            .map { String(format: "%02x", $0) }.joined()
        #expect(digest == expectedDigest)
        let bundled = try await SwiftFulcrum.ServerCatalog.Repository.bundled.loadServers(for: network, fallback: [])
        #expect(bundled.map(\.absoluteString) == expectedURLs)
    }

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
