// Fulcrum+Configuration.swift

import Foundation

extension Fulcrum {
    public struct Configuration: Sendable {
        public var tls: WebSocket.TLSDescriptor?
        public var heartbeat: WebSocket.Heartbeat.Configuration?
        public var reconnect: WebSocket.Reconnector.Configuration
        public var metrics: MetricsCollectable?
        public var logger: Log.Handler?
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        
        public static let `default` = Configuration()
        
        public init(
            tls: WebSocket.TLSDescriptor? = nil,
            heartbeat: WebSocket.Heartbeat.Configuration? = nil,
            reconnect: WebSocket.Reconnector.Configuration = .defaultConfiguration,
            metrics: MetricsCollectable? = nil,
            logger: Log.Handler? = nil,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10
        ) {
            self.tls = tls
            self.heartbeat = heartbeat
            self.reconnect = reconnect
            self.metrics = metrics
            self.logger = logger
            self.urlSession = urlSession
            self.connectionTimeout = connectionTimeout
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
