// WebSocketModel+Configuration.swift

import Foundation
import Network

extension WebSocketModel {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024
        
        let session: URLSession?
        let tlsDescriptor: TLSDescriptorModel?
        let metrics: MetricsClient?
        let logger: LogModel.AdapterModel?
        let maximumMessageSize: Int
        let serverCatalogLoader: FulcrumServerCatalogRepository
        let network: FulcrumClient.Configuration.NetworkModel
        
        init(session: URLSession? = nil,
             tlsDescriptor: TLSDescriptorModel? = nil,
             metrics: MetricsClient? = nil,
             logger: LogModel.AdapterModel? = nil,
             maximumMessageSize: Int = defaultMaximumMessageSize,
             serverCatalogLoader: FulcrumServerCatalogRepository = .bundled,
             network: FulcrumClient.Configuration.NetworkModel = .mainnet) {
            self.session = session
            self.tlsDescriptor = tlsDescriptor
            self.metrics = metrics
            self.logger = logger
            self.maximumMessageSize = maximumMessageSize
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
        }
    }
    
    func updateMetrics(_ collector: MetricsClient?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: LogModel.AdapterModel?) {
        self.logger = handler ?? LogModel.NoOperationAdapterModel()
    }
}
