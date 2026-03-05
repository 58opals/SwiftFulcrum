// WebSocketModel+Configuration.swift

import Foundation
import Network

extension WebSocketModel {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024
        
        let session: URLSession?
        let tlsDescriptor: TLSDescriptor?
        let metrics: SwiftFulcrum.Metrics.ClientProtocol?
        let logger: SwiftFulcrum.Logging.Adapter?
        let maximumMessageSize: Int
        let serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        let network: SwiftFulcrum.Client.Configuration.NetworkModel
        
        init(session: URLSession? = nil,
             tlsDescriptor: TLSDescriptor? = nil,
             metrics: SwiftFulcrum.Metrics.ClientProtocol? = nil,
             logger: SwiftFulcrum.Logging.Adapter? = nil,
             maximumMessageSize: Int = defaultMaximumMessageSize,
             serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
             network: SwiftFulcrum.Client.Configuration.NetworkModel = .mainnet) {
            self.session = session
            self.tlsDescriptor = tlsDescriptor
            self.metrics = metrics
            self.logger = logger
            self.maximumMessageSize = maximumMessageSize
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
        }
    }
    
    func updateMetrics(_ collector: SwiftFulcrum.Metrics.ClientProtocol?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: SwiftFulcrum.Logging.Adapter?) {
        self.logger = handler ?? SwiftFulcrum.Logging.NoOperationAdapter()
    }
}
