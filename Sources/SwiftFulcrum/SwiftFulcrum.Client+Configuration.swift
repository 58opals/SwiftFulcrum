// SwiftFulcrum.Client+Configuration.swift

import Foundation
import Network

extension SwiftFulcrum.Client {
    public struct Configuration: Sendable {
        public enum NetworkModel: Sendable {
            case mainnet
            case testnet
            
            var resourceName: String {
                switch self {
                case .mainnet: return "servers.mainnet"
                case .testnet: return "servers.testnet"
                }
            }
        }
        
        public struct TLSDescriptorModel: Sendable {
            public let delegate: URLSessionDelegate?
            public let options: NWProtocolTLS.Options
            
            public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
                self.options = options
                self.delegate = delegate
            }
        }
        
        public struct ReconnectModel: Sendable {
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
        
        public var tlsDescriptor: TLSDescriptorModel?
        public var reconnect: ReconnectModel
        public var metrics: SwiftFulcrum.Metrics.ClientProtocol?
        public var logger: SwiftFulcrum.Logging.Adapter?
        public var isLoggingEnabled: Bool
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        public var network: NetworkModel
        public var protocolNegotiation: ProtocolNegotiationModel
        
        public static let basic = Configuration()
        
        public init(
            tlsDescriptor: TLSDescriptorModel? = nil,
            reconnect: ReconnectModel = .basic,
            metrics: SwiftFulcrum.Metrics.ClientProtocol? = nil,
            logger: SwiftFulcrum.Logging.Adapter? = nil,
            isLoggingEnabled: Bool = true,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = 64 * 1024 * 1024,
            bootstrapServers: [URL]? = nil,
            serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
            network: NetworkModel = .mainnet,
            protocolNegotiation: ProtocolNegotiationModel = .init()
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

extension SwiftFulcrum.Client.Configuration.ReconnectModel {
    var reconnectorConfiguration: WebSocketModel.Reconnector.Configuration {
        .init(
            maximumReconnectionAttempts: maximumReconnectionAttempts,
            reconnectionDelay: reconnectionDelay,
            maximumDelay: maximumDelay,
            jitterRange: jitterRange
        )
    }
}
