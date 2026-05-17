// WebSocketReconnectorValidator~RotationPolicy.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    @Test("Reconnector rotates through bundled servers", .timeLimit(.minutes(1)))
    func rotateThroughBundledServers() async throws {
        let configuration = WebSocketConnection.Reconnector.Configuration.basic
        let servers = try WebSocketConnection.Server.decodeBundledServers(for: .mainnet)

        guard let current = servers.first else {
            Issue.record("Bundled servers are unavailable")
            return
        }

        let reconnector = WebSocketConnection.Reconnector(configuration, network: .mainnet)
        let rotation = try await reconnector.buildCandidateRotation(preferredURL: nil, currentURL: current)
        let serverKeys = servers.map(WebSocketConnection.Reconnector.canonicalize)
        let rotationKeys = rotation.map(WebSocketConnection.Reconnector.canonicalize)
        let currentKey = WebSocketConnection.Reconnector.canonicalize(current)

        #expect(rotation.count == servers.count)
        #expect(rotationKeys.count == Set(rotationKeys).count)
        #expect(Set(rotationKeys) == Set(serverKeys))
        #expect(rotationKeys.last == currentKey)
        #expect(rotationKeys.dropLast().allSatisfy { $0 != currentKey })
        #expect(Set(rotationKeys.dropLast()) == Set(serverKeys.filter { $0 != currentKey }))
    }

    @Test("Reconnector canonicalizes case-insensitive URL components")
    func canonicalizeCaseInsensitiveURLComponents() throws {
        let uppercased = try #require(URL(string: "WSS://Fulcrum.Example:50004"))
        let lowercased = try #require(URL(string: "wss://fulcrum.example:50004"))

        #expect(WebSocketConnection.Reconnector.canonicalize(uppercased) == WebSocketConnection.Reconnector.canonicalize(lowercased))
        #expect(WebSocketConnection.Reconnector.deduplicate([uppercased, lowercased]).count == 1)
    }

    @Test("Reconnector canonicalizes empty and root URL paths")
    func canonicalizeEmptyAndRootURLPaths() throws {
        let emptyPath = try #require(URL(string: "wss://fulcrum.example:50004"))
        let rootPath = try #require(URL(string: "wss://fulcrum.example:50004/"))

        #expect(WebSocketConnection.Reconnector.canonicalize(emptyPath) == WebSocketConnection.Reconnector.canonicalize(rootPath))
        #expect(WebSocketConnection.Reconnector.deduplicate([emptyPath, rootPath]).count == 1)
    }

    @Test("Reconnector includes configured bootstrap servers in fallback rotation")
    func includeConfiguredBootstrapServersInFallbackRotation() async throws {
        let current = try #require(URL(string: "wss://current.fulcrum.example"))
        let bootstrap = try #require(URL(string: "wss://bootstrap.fulcrum.example"))
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            fallback
        }
        let clientConfiguration = SwiftFulcrum.Client.Configuration(
            bootstrapServers: [bootstrap],
            serverCatalogLoader: loader
        )
        let webSocket = WebSocketConnection(
            url: current,
            configuration: clientConfiguration.convertToWebSocketConfiguration()
        )

        let rotation = try await webSocket.reconnector.buildCandidateRotation(
            preferredURL: nil,
            currentURL: current
        )
        let rotationKeys = rotation.map(WebSocketConnection.Reconnector.canonicalize)

        #expect(rotationKeys == [bootstrap, current].map(WebSocketConnection.Reconnector.canonicalize))
    }

    @Test("Reconnector filters invalid catalog fallback entries")
    func filterInvalidCatalogFallbackEntries() async throws {
        let current = try #require(URL(string: "wss://current.fulcrum.example"))
        let invalidBootstrap = try #require(URL(string: "http://invalid.fulcrum.example"))
        let validBootstrap = try #require(URL(string: "wss://valid.fulcrum.example"))
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            fallback
        }
        let clientConfiguration = SwiftFulcrum.Client.Configuration(
            bootstrapServers: [invalidBootstrap, validBootstrap],
            serverCatalogLoader: loader
        )
        let webSocket = WebSocketConnection(
            url: current,
            configuration: clientConfiguration.convertToWebSocketConfiguration()
        )

        let rotation = try await webSocket.reconnector.buildCandidateRotation(
            preferredURL: nil,
            currentURL: current
        )
        let rotationKeys = rotation.map(WebSocketConnection.Reconnector.canonicalize)

        #expect(rotationKeys == [validBootstrap, current].map(WebSocketConnection.Reconnector.canonicalize))
    }

    @Test("Reconnector filters invalid fallback entries after catalog cache is warm")
    func filterInvalidFallbackEntriesAfterCatalogCacheIsWarm() async throws {
        let firstCurrent = try #require(URL(string: "wss://first.fulcrum.example"))
        let secondCurrent = try #require(URL(string: "wss://second.fulcrum.example"))
        let invalidBootstrap = try #require(URL(string: "http://invalid.fulcrum.example"))
        let validBootstrap = try #require(URL(string: "wss://valid.fulcrum.example"))
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            fallback
        }
        let clientConfiguration = SwiftFulcrum.Client.Configuration(
            bootstrapServers: [invalidBootstrap, validBootstrap],
            serverCatalogLoader: loader
        )
        let webSocket = WebSocketConnection(
            url: firstCurrent,
            configuration: clientConfiguration.convertToWebSocketConfiguration()
        )

        _ = try await webSocket.reconnector.buildCandidateRotation(
            preferredURL: nil,
            currentURL: firstCurrent
        )
        let rotation = try await webSocket.reconnector.buildCandidateRotation(
            preferredURL: nil,
            currentURL: secondCurrent
        )
        let rotationKeys = rotation.map(WebSocketConnection.Reconnector.canonicalize)

        #expect(!rotationKeys.contains(WebSocketConnection.Reconnector.canonicalize(invalidBootstrap)))
        #expect(rotationKeys.contains(WebSocketConnection.Reconnector.canonicalize(validBootstrap)))
        #expect(rotationKeys.last == WebSocketConnection.Reconnector.canonicalize(secondCurrent))
    }
}
