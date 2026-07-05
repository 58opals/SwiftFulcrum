// WebSocketConnection+Configuration.swift

import Foundation

extension WebSocketConnection {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024

        let maximumMessageSize: Int
        let bootstrapServers: [URL]
        let serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        let network: SwiftFulcrum.Client.Configuration.Network

        init(maximumMessageSize: Int = defaultMaximumMessageSize,
             bootstrapServers: [URL] = .init(),
             serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
             network: SwiftFulcrum.Client.Configuration.Network = .mainnet) {
            self.maximumMessageSize = maximumMessageSize
            self.bootstrapServers = bootstrapServers
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
        }
    }
}
