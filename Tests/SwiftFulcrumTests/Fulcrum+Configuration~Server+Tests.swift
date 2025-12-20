import Foundation
import Testing
@testable import SwiftFulcrum

struct FulcrumServerCatalogLoaderTests {
    @Test("Loads bundled catalog when available")
    func loadsBundledCatalog() async throws {
        let servers = try await FulcrumServerCatalogLoader.bundled.loadServers(
            for: .mainnet,
            fallback: .init()
        )
        
        #expect(!servers.isEmpty)
        #expect(servers.allSatisfy { ["ws", "wss"].contains($0.scheme?.lowercased()) })
    }
    
    @Test("Falls back when bundled catalog is unavailable")
    func fallsBackToBootstrapList() async throws {
        let fallbackServers = [URL(string: "wss://fallback.fulcrum.example")!]
        let loader = FulcrumServerCatalogLoader { _, fallback in
            try await Task.detached(priority: .utility) {
                let sanitized = FulcrumServerCatalogLoader.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw Fulcrum.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }
        
        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)
        
        #expect(servers == fallbackServers)
    }
    
    @Test("Sanitizes fallback catalog entries")
    func sanitizesFallbackCatalog() async throws {
        let fallbackServers = [
            URL(string: "http://invalid.fulcrum.example")!,
            URL(string: "wss://valid.fulcrum.example")!
        ]
        let loader = FulcrumServerCatalogLoader { _, fallback in
            try await Task.detached(priority: .utility) {
                let sanitized = FulcrumServerCatalogLoader.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw Fulcrum.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }
        
        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)
        
        #expect(servers.count == 1)
        #expect(servers.first?.absoluteString == "wss://valid.fulcrum.example")
    }
    
    @Test("Throws when both bundled and fallback catalogs are empty")
    func throwsWhenCatalogCannotBeBuilt() async {
        let loader = FulcrumServerCatalogLoader { _, _ in
            try await Task.detached(priority: .utility) { () -> [URL] in
                let fallback: [URL] = []
                let sanitized = FulcrumServerCatalogLoader.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw Fulcrum.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }
        
        do {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
            Issue.record("Expected loader to throw when no servers are available")
        } catch let error as Fulcrum.Error {
            switch error {
            case .transport(.setupFailed): break
            default: Issue.record("Unexpected Fulcrum.Error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Uses injected catalog loader during Fulcrum initialization")
    func usesInjectedCatalogLoader() async throws {
        let expectedServer = URL(string: "wss://injected.fulcrum.example")!
        let loader = FulcrumServerCatalogLoader { _, _ in [expectedServer] }
        let configuration = Fulcrum.Configuration(serverCatalogLoader: loader)
        
        let fulcrum = try await Fulcrum(configuration: configuration)
        let client = await fulcrum.client
        let transport = await client.transport
        let endpoint = await transport.endpoint
        
        #expect(endpoint == expectedServer)
    }
}
