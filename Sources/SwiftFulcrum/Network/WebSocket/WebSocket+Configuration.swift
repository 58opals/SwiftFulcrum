// WebSocket+Configuration.swift

import Foundation
import Network

extension WebSocket {
    public struct Configuration: Sendable {
        public let session: URLSession?
        public let tls: TLSDescriptor?
        public let metrics: MetricsCollectable?
        public let logger: Log.Handler?
        
        public init(session: URLSession? = nil,
                    tls: TLSDescriptor? = nil,
                    metrics: MetricsCollectable? = nil,
                    logger: Log.Handler? = nil) {
            self.session = session
            self.tls = tls
            self.metrics = metrics
            self.logger = logger
        }
    }
    
    func updateMetrics(_ collector: MetricsCollectable?) {
        self.metrics = collector
    }
    
    func updateLogger(_ handler: Log.Handler?) {
        self.logger = handler ?? Log.NoOpHandler()
    }
    
    public struct TLSDescriptor: Sendable {
        public let options: NWProtocolTLS.Options
        public let delegate: URLSessionDelegate?
        
        public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
            self.options = options
            self.delegate = delegate
        }
    }
}
