// Fulcrum+Configuration.swift

import Foundation

extension Fulcrum {
    public struct Configuration: Sendable {
        public enum Network: Sendable {
            case mainnet
            case testnet
            
            var resourceName: String {
                switch self {
                case .mainnet: return "servers.mainnet"
                case .testnet: return "servers.testnet"
                }
            }
        }
        
        public var tlsDescriptor: WebSocket.TLSDescriptor?
        public var reconnect: WebSocket.Reconnector.Configuration
        public var metrics: MetricsCollectable?
        public var logger: Log.Handler?
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var network: Network
        
        public static let basic = Configuration()
        
        public init(
            tlsDescriptor: WebSocket.TLSDescriptor? = nil,
            reconnect: WebSocket.Reconnector.Configuration = .basic,
            metrics: MetricsCollectable? = nil,
            logger: Log.Handler? = nil,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = WebSocket.Configuration.defaultMaximumMessageSize,
            bootstrapServers: [URL]? = nil,
            network: Network = .mainnet
        ) {
            self.tlsDescriptor = tlsDescriptor
            self.reconnect = reconnect
            self.metrics = metrics
            self.logger = logger
            self.urlSession = urlSession
            self.connectionTimeout = connectionTimeout
            self.maximumMessageSize = maximumMessageSize
            self.bootstrapServers = bootstrapServers
            self.network = network
        }
    }
}

extension Fulcrum.Configuration {
    func convertToWebSocketConfiguration() -> WebSocket.Configuration {
        WebSocket.Configuration(
            session: urlSession,
            tlsDescriptor: tlsDescriptor,
            metrics: metrics,
            logger: logger,
            maximumMessageSize: maximumMessageSize,
            network: network
        )
    }
}
