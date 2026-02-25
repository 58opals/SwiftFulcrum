import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ServerCatalogRepositoryValidator {
    @Test("Loads bundled catalog when available")
    func loadBundledCatalog() async throws {
        let servers = try await FulcrumServerCatalogRepository.bundled.loadServers(
            for: .mainnet,
            fallback: .init()
        )

        #expect(!servers.isEmpty)
        #expect(servers.allSatisfy { ["ws", "wss"].contains($0.scheme?.lowercased()) })
    }

    @Test("Falls back when bundled catalog is unavailable")
    func loadFallbackBootstrapList() async throws {
        let fallbackServers = [URL(string: "wss://fallback.fulcrum.example")!]
        let loader = FulcrumServerCatalogRepository { _, fallback in
            try await Task.detached(priority: .utility) {
                let sanitized = FulcrumServerCatalogRepository.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw FulcrumClient.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }

        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)

        #expect(servers == fallbackServers)
    }

    @Test("Sanitizes fallback catalog entries")
    func sanitizeFallbackCatalog() async throws {
        let fallbackServers = [
            URL(string: "http://invalid.fulcrum.example")!,
            URL(string: "wss://valid.fulcrum.example")!
        ]
        let loader = FulcrumServerCatalogRepository { _, fallback in
            try await Task.detached(priority: .utility) {
                let sanitized = FulcrumServerCatalogRepository.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw FulcrumClient.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }

        let servers = try await loader.loadServers(for: .mainnet, fallback: fallbackServers)

        #expect(servers.count == 1)
        #expect(servers.first?.absoluteString == "wss://valid.fulcrum.example")
    }

    @Test("Throws when both bundled and fallback catalogs are empty")
    func throwWhenCatalogCannotBeBuilt() async {
        let loader = FulcrumServerCatalogRepository { _, _ in
            try await Task.detached(priority: .utility) { () -> [URL] in
                let fallback: [URL] = .init()
                let sanitized = FulcrumServerCatalogRepository.sanitizeServers(fallback)
                guard !sanitized.isEmpty else { throw FulcrumClient.Error.transport(.setupFailed) }
                return sanitized
            }.value
        }

        do {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
            Issue.record("Expected loader to throw when no servers are available")
        } catch let error as FulcrumClient.Error {
            switch error {
            case .transport(.setupFailed):
                break
            default:
                Issue.record("Unexpected FulcrumClient.Error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Uses injected catalog loader during FulcrumClient initialization")
    func useInjectedCatalogLoader() async throws {
        let expectedServer = URL(string: "wss://injected.fulcrum.example")!
        let loader = FulcrumServerCatalogRepository { _, _ in [expectedServer] }
        let configuration = FulcrumClient.Configuration(serverCatalogLoader: loader)

        let clientInterface = try await FulcrumClient(configuration: configuration)
        let client = await clientInterface.client
        let transport = await client.transport
        let endpoint = await transport.endpoint

        #expect(endpoint == expectedServer)
    }
}
