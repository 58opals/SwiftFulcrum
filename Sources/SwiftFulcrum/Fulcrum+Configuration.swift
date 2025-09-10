// Fulcrum+Configuration.swift

import Foundation

extension Fulcrum {
    public struct Configuration: Sendable {
        public var tls: WebSocket.TLSDescriptor?
        public var reconnect: WebSocket.Reconnector.Configuration
        public var metrics: MetricsCollectable?
        public var logger: Log.Handler?
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        
        public var bootstrapServers: [URL]?
        
        public static let basic = Configuration()
        
        public init(
            tls: WebSocket.TLSDescriptor? = nil,
            reconnect: WebSocket.Reconnector.Configuration = .defaultConfiguration,
            metrics: MetricsCollectable? = nil,
            logger: Log.Handler? = nil,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            bootstrapServers: [URL]? = nil
        ) {
            self.tls = tls
            self.reconnect = reconnect
            self.metrics = metrics
            self.logger = logger
            self.urlSession = urlSession
            self.connectionTimeout = connectionTimeout
            self.bootstrapServers = bootstrapServers
        }
    }
}

extension Fulcrum.Configuration {
    func convertToWebSocketConfiguration() -> WebSocket.Configuration {
        WebSocket.Configuration(
            session: urlSession,
            tls: tls,
            metrics: metrics,
            logger: logger
        )
    }
}
