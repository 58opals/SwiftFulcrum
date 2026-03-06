import Foundation
import Network

extension SwiftFulcrum.Client {
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
        
        public struct TLSDescriptor: Sendable {
            public let delegate: URLSessionDelegate?
            public let options: NWProtocolTLS.Options
            
            public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
                self.options = options
                self.delegate = delegate
            }
        }
        
        public struct ReconnectPolicy: Sendable {
            public var maximumReconnectionAttempts: Int
            public var reconnectionDelay: TimeInterval
            public var maximumDelay: TimeInterval
            public var jitterRange: ClosedRange<TimeInterval>
            
            public var isUnlimited: Bool { maximumReconnectionAttempts <= 0 }
            
            public static let basic = Self(
                maximumReconnectionAttempts: 1,
                reconnectionDelay: 1.5,
                maximumDelay: 30,
                jitterRange: 0.8 ... 1.3
            )
            
            public init(
                maximumReconnectionAttempts: Int,
                reconnectionDelay: TimeInterval,
                maximumDelay: TimeInterval,
                jitterRange: ClosedRange<TimeInterval>
            ) {
                self.maximumReconnectionAttempts = maximumReconnectionAttempts
                self.reconnectionDelay = reconnectionDelay
                self.maximumDelay = maximumDelay
                self.jitterRange = jitterRange
            }
        }
        
        public var tlsDescriptor: TLSDescriptor?
        public var reconnect: ReconnectPolicy
        public var metrics: SwiftFulcrum.Metrics.MetricsClientProtocol?
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
            metrics: SwiftFulcrum.Metrics.MetricsClientProtocol? = nil,
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
    func convertToWebSocketConfiguration() -> WebSocketModel.Configuration {
        let socketTLSDescriptor = tlsDescriptor.map { WebSocketModel.TLSDescriptor($0) }
        
        return WebSocketModel.Configuration(
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

extension SwiftFulcrum.Client.Configuration.ReconnectPolicy {
    var reconnectorConfiguration: WebSocketModel.Reconnector.Configuration {
        .init(
            maximumReconnectionAttempts: maximumReconnectionAttempts,
            reconnectionDelay: reconnectionDelay,
            maximumDelay: maximumDelay,
            jitterRange: jitterRange
        )
    }
}
