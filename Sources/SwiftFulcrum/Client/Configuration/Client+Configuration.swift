// Client+Configuration.swift

import Foundation
import Network

extension SwiftFulcrum.Client {
    public struct Configuration: Sendable {
        public var tlsDescriptor: TLSDescriptor?
        public var reconnect: ReconnectPolicy
        public var metrics: SwiftFulcrum.Metrics.MetricsClient?
        public var logger: SwiftFulcrum.Logging.Adapter?
        public var isLoggingEnabled: Bool
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        public var network: Network
        public var protocolNegotiation: ProtocolNegotiation
        
        public static let basic = Configuration()
        
        public init(
            tlsDescriptor: TLSDescriptor? = nil,
            reconnect: ReconnectPolicy = .basic,
            metrics: SwiftFulcrum.Metrics.MetricsClient? = nil,
            logger: SwiftFulcrum.Logging.Adapter? = nil,
            isLoggingEnabled: Bool = true,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = 64 * 1024 * 1024,
            bootstrapServers: [URL]? = nil,
            serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
            network: Network = .mainnet,
            protocolNegotiation: ProtocolNegotiation = .init()
        ) {
            self.tlsDescriptor = tlsDescriptor
            self.reconnect = reconnect
            self.metrics = metrics
            self.logger = logger
            self.isLoggingEnabled = isLoggingEnabled
            self.urlSession = urlSession
            self.connectionTimeout = connectionTimeout
            self.maximumMessageSize = maximumMessageSize
            self.bootstrapServers = bootstrapServers
            self.serverCatalogLoader = serverCatalogLoader
            self.network = network
            self.protocolNegotiation = protocolNegotiation
        }
    }
}

extension SwiftFulcrum.Client.Configuration {
    func convertToWebSocketConfiguration() -> WebSocketConnection.Configuration {
        let socketTLSDescriptor = tlsDescriptor.map { WebSocketConnection.TLSDescriptor($0) }
        
        return WebSocketConnection.Configuration(
            session: urlSession,
            tlsDescriptor: socketTLSDescriptor,
            metrics: metrics,
            logger: resolvedLogger,
            maximumMessageSize: maximumMessageSize,
            serverCatalogLoader: serverCatalogLoader,
            network: network
        )
    }
    
    var resolvedLogger: SwiftFulcrum.Logging.Adapter? {
        guard isLoggingEnabled else { return SwiftFulcrum.Logging.NoOperationAdapter() }
        return logger
    }
}
