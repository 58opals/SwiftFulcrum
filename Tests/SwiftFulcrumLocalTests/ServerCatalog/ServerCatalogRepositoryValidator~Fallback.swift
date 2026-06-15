// ServerCatalogRepositoryValidator~Fallback.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
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

        let servers = try await loadSanitizedFallbackServers(fallbackServers)

        #expect(servers.count == 1)
        #expect(servers.first?.absoluteString == "wss://valid.fulcrum.example")
    }

    @Test(
        "Sanitizes fallback catalog entries with credentials",
        arguments: [
            "wss://user@invalid.fulcrum.example",
            "wss://user:pass@invalid.fulcrum.example"
        ]
    )
    func sanitizeFallbackCatalogEntriesWithCredentials(_ invalidURLString: String) async throws {
        let validServer = URL(string: "wss://valid.fulcrum.example")!
        let fallbackServers = [
            URL(string: invalidURLString)!,
            validServer
        ]

        let servers = try await loadSanitizedFallbackServers(fallbackServers)

        #expect(servers == [validServer])
    }

    @Test("Sanitizes fallback catalog entries with fragments")
    func sanitizeFallbackCatalogEntriesWithFragments() async throws {
        let validServer = URL(string: "wss://valid.fulcrum.example")!
        let fallbackServers = [
            URL(string: "wss://invalid.fulcrum.example#fragment")!,
            validServer
        ]

        let servers = try await loadSanitizedFallbackServers(fallbackServers)

        #expect(servers == [validServer])
    }

}
