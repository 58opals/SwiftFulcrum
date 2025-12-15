// WebSocket+Configuration.swift

import Foundation
import Network

extension WebSocket {
    struct Configuration: Sendable {
        static let defaultMaximumMessageSize = 64 * 1024 * 1024
        
        let session: URLSession?
        let tlsDescriptor: TLSDescriptor?
        let metrics: MetricsCollectable?
        let logger: Log.Handler?
        let maximumMessageSize: Int
        let network: Fulcrum.Configuration.Network
        
        init(session: URLSession? = nil,
             tlsDescriptor: TLSDescriptor? = nil,
             metrics: MetricsCollectable? = nil,
             logger: Log.Handler? = nil,
             maximumMessageSize: Int = defaultMaximumMessageSize,
             network: Fulcrum.Configuration.Network = .mainnet) {
            self.session = session
            self.tlsDescriptor = tlsDescriptor
            self.metrics = metrics
            self.logger = logger
            self.maximumMessageSize = maximumMessageSize
            self.network = network
        }
    }
    
    func updateMetrics(_ collector: MetricsCollectable?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: Log.Handler?) {
        self.logger = handler ?? Log.NoOpHandler()
    }
    
    struct TLSDescriptor: Sendable {
        let options: NWProtocolTLS.Options
        let delegate: URLSessionDelegate?
        
        init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
            self.options = options
            self.delegate = delegate
        }
        
        init(_ descriptor: Fulcrum.Configuration.TLSDescriptor) {
            self.options = descriptor.options
            self.delegate = descriptor.delegate
        }
    }
}
