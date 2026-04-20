// WebSocketConnection+Configuration.swift

import Foundation
import Network

extension WebSocketConnection {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024
        
        let tlsDescriptor: TLSDescriptor?
        let metrics: SwiftFulcrum.Metrics.MetricsClient?
        let logger: SwiftFulcrum.Logging.Adapter?
        let maximumMessageSize: Int
        let serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        let network: SwiftFulcrum.Client.Configuration.Network
        
        init(tlsDescriptor: TLSDescriptor? = nil,
             metrics: SwiftFulcrum.Metrics.MetricsClient? = nil,
             logger: SwiftFulcrum.Logging.Adapter? = nil,
             maximumMessageSize: Int = defaultMaximumMessageSize,
             serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
             network: SwiftFulcrum.Client.Configuration.Network = .mainnet) {
            self.tlsDescriptor = tlsDescriptor
            self.metrics = metrics
            self.logger = logger
            self.maximumMessageSize = maximumMessageSize
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
        }
    }
    
    func updateMetrics(_ collector: SwiftFulcrum.Metrics.MetricsClient?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: SwiftFulcrum.Logging.Adapter?) {
        self.logger = handler ?? SwiftFulcrum.Logging.NoOperationAdapter()
    }
}
