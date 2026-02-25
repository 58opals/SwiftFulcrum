// WebSocketModel+ReconnectorModel.swift

import Foundation

extension WebSocketModel {
    actor ReconnectorModel {
        struct Configuration: Sendable {
            var maximumReconnectionAttempts: Int
            var reconnectionDelay: TimeInterval
            var maximumDelay: TimeInterval
            var jitterRange: ClosedRange<TimeInterval>

            var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }

            static let basic = Self(maximumReconnectionAttempts: 1,
                                    reconnectionDelay: 1.5,
                                    maximumDelay: 30,
                                    jitterRange: 0.8 ... 1.3)

            init(maximumReconnectionAttempts: Int,
                 reconnectionDelay: TimeInterval,
                 maximumDelay: TimeInterval,
                 jitterRange: ClosedRange<TimeInterval>) {
                self.maximumReconnectionAttempts = maximumReconnectionAttempts
                self.reconnectionDelay = reconnectionDelay
                self.maximumDelay = maximumDelay
                self.jitterRange = jitterRange
            }
        }

        let configuration: Configuration
        var reconnectionAttempts: Int
        let network: FulcrumClient.Configuration.NetworkModel
        let serverCatalogLoader: FulcrumServerCatalogRepository
        var serverCatalog: [URL]
        var nextServerIndex: Int

        let sleep: @Sendable (Duration) async throws -> Void
        let jitter: @Sendable (ClosedRange<Double>) -> Double

        var attemptCount: Int { reconnectionAttempts }

        init(_ configuration: Configuration,
             reconnectionAttempts: Int = 0,
             network: FulcrumClient.Configuration.NetworkModel,
             serverCatalogLoader: FulcrumServerCatalogRepository = .bundled,
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
