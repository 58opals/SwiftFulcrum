// Fulcrum+Configuration.swift

import Foundation
import Network

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
        
        public struct TLSDescriptor: Sendable {
            public let delegate: URLSessionDelegate?
            public let options: NWProtocolTLS.Options
            
            public init(options: NWProtocolTLS.Options = .init(), delegate: URLSessionDelegate? = nil) {
                self.options = options
                self.delegate = delegate
            }
        }
        
        public struct Reconnect: Sendable {
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
        public var reconnect: Reconnect
        public var metrics: MetricsCollectable?
        public var logger: Log.Handler?
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var network: Network
        
        public static let basic = Configuration()
        
        public init(
            tlsDescriptor: TLSDescriptor? = nil,
            reconnect: Reconnect = .basic,
            metrics: MetricsCollectable? = nil,
            logger: Log.Handler? = nil,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = 64 * 1024 * 1024,
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
        let socketTLSDescriptor = tlsDescriptor.map { WebSocket.TLSDescriptor($0) }
        
        return WebSocket.Configuration(
            session: urlSession,
            tlsDescriptor: socketTLSDescriptor,
            metrics: metrics,
            logger: logger,
            maximumMessageSize: maximumMessageSize,
            network: network
        )
    }
}

extension Fulcrum.Configuration.Reconnect {
    var reconnectorConfiguration: WebSocket.Reconnector.Configuration {
        .init(
            maximumReconnectionAttempts: maximumReconnectionAttempts,
            reconnectionDelay: reconnectionDelay,
            maximumDelay: maximumDelay,
            jitterRange: jitterRange
        )
    }
}
