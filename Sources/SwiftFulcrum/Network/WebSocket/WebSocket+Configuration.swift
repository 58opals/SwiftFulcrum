// WebSocket+Configuration.swift

import Foundation
import Network

extension WebSocket {
    public struct Configuration: Sendable {
        public static let defaultMaximumMessageSize = 64 * 1024 * 1024
        
        public let session: URLSession?
        public let tlsDescriptor: TLSDescriptor?
        public let metrics: MetricsCollectable?
        public let logger: Log.Handler?
        public let maximumMessageSize: Int
        
        public init(session: URLSession? = nil,
                    tlsDescriptor: TLSDescriptor? = nil,
                    metrics: MetricsCollectable? = nil,
                    logger: Log.Handler? = nil,
                    maximumMessageSize: Int = defaultMaximumMessageSize) {
            self.session = session
            self.tlsDescriptor = tlsDescriptor
            self.metrics = metrics
            self.logger = logger
            self.maximumMessageSize = maximumMessageSize
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
