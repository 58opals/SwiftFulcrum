// WebSocketConnection+Configuration.swift

import Foundation
import Network

extension WebSocketConnection {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024

        let tlsDescriptor: TLSDescriptor?
        let maximumMessageSize: Int
        let bootstrapServers: [URL]
        let serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        let network: SwiftFulcrum.Client.Configuration.Network

        init(tlsDescriptor: TLSDescriptor? = nil,
             maximumMessageSize: Int = defaultMaximumMessageSize,
             bootstrapServers: [URL] = .init(),
             serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
             network: SwiftFulcrum.Client.Configuration.Network = .mainnet) {
            self.tlsDescriptor = tlsDescriptor
            self.maximumMessageSize = maximumMessageSize
            self.bootstrapServers = bootstrapServers
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
        }
    }
}
