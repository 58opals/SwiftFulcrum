// WebSocketConnection+Reconnector.swift

import Foundation

extension WebSocketConnection {
    actor Reconnector {
        let configuration: Configuration
        var reconnectionAttempts: Int
        let network: SwiftFulcrum.Client.Configuration.Network
        let serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        var serverCatalog: [URL]
        var nextServerIndex: Int

        let sleep: @Sendable (Duration) async throws -> Void
        let jitter: @Sendable (ClosedRange<Double>) -> Double

        var attemptCount: Int { reconnectionAttempts }

        init(_ configuration: Configuration,
             reconnectionAttempts: Int = 0,
             network: SwiftFulcrum.Client.Configuration.Network,
             serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
             sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in try await Task.sleep(for: duration) },
             jitter: @escaping @Sendable (ClosedRange<Double>) -> Double = { range in .random(in: range) }) {
            self.configuration = configuration
            self.reconnectionAttempts = reconnectionAttempts
            self.network = network
            self.serverCatalogLoader = serverCatalogLoader
            self.serverCatalog = .init()
            self.nextServerIndex = 0
            self.sleep = sleep
            self.jitter = jitter
        }

        func resetReconnectionAttemptCount() {
            reconnectionAttempts = 0
        }
    }
}
