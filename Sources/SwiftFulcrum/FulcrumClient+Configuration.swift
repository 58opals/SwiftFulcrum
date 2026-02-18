// FulcrumClient+Configuration.swift

import Foundation
import Network

extension FulcrumClient {
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
        public var metrics: MetricsClient?
        public var logger: LogModel.HandlerModel?
        public var isLoggingEnabled: Bool
        public var urlSession: URLSession?
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var serverCatalogLoader: FulcrumServerCatalogRepository
        public var network: NetworkModel
        public var protocolNegotiation: ProtocolNegotiationModel
        
        public static let basic = Configuration()
        
        public init(
            tlsDescriptor: TLSDescriptorModel? = nil,
            reconnect: ReconnectModel = .basic,
            metrics: MetricsClient? = nil,
            logger: LogModel.HandlerModel? = nil,
            isLoggingEnabled: Bool = true,
            urlSession: URLSession? = nil,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = 64 * 1024 * 1024,
            bootstrapServers: [URL]? = nil,
            serverCatalogLoader: FulcrumServerCatalogRepository = .bundled,
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

extension FulcrumClient.Configuration {
    func convertToWebSocketConfiguration() -> WebSocketModel.Configuration {
        let socketTLSDescriptor = tlsDescriptor.map { WebSocketModel.TLSDescriptorModel($0) }
        
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
    
    var resolvedLogger: LogModel.HandlerModel? {
        guard isLoggingEnabled else { return LogModel.NoOpHandlerModel() }
        return logger
    }
}

extension FulcrumClient.Configuration.ReconnectModel {
    var reconnectorConfiguration: WebSocketModel.ReconnectorModel.Configuration {
        .init(
            maximumReconnectionAttempts: maximumReconnectionAttempts,
            reconnectionDelay: reconnectionDelay,
            maximumDelay: maximumDelay,
            jitterRange: jitterRange
        )
    }
}

public struct FulcrumServerCatalogRepository: Sendable {
    enum KindModel { case bundled, constant, custom }
    
    private let kind: KindModel
    private let loadCatalog: @Sendable (FulcrumClient.Configuration.NetworkModel, [URL]) async throws -> [URL]
    
    public init(load: @escaping @Sendable (FulcrumClient.Configuration.NetworkModel, [URL]) async throws -> [URL]) {
        self.init(load: load, kind: .custom)
    }
    
    init(load: @escaping @Sendable (FulcrumClient.Configuration.NetworkModel, [URL]) async throws -> [URL], kind: KindModel) {
        self.loadCatalog = load
        self.kind = kind
    }
    
    public func loadServers(
        for network: FulcrumClient.Configuration.NetworkModel,
        fallback: [URL]
    ) async throws -> [URL] {
        try await loadCatalog(network, fallback)
    }
    
    var isBundled: Bool { kind == .bundled }
}

extension FulcrumServerCatalogRepository {
    public static let bundled = Self(load: { network, fallback in
        try await Task.detached(priority: .utility) {
            if let bundled = try? WebSocketModel.ServerModel.decodeBundledServers(for: network), !bundled.isEmpty {
                return bundled
            }
            
            let sanitizedFallback = sanitizeServers(fallback)
            guard !sanitizedFallback.isEmpty else { throw FulcrumClient.Error.transport(.setupFailed) }
            return sanitizedFallback
        }.value
    }, kind: .bundled)
    
    public static func makeConstant(_ servers: [URL]) -> Self {
        Self(load: { _, _ in servers }, kind: .constant)
    }
    
    static func sanitizeServers(_ servers: [URL]) -> [URL] {
        servers.filter { server in
            guard let scheme = server.scheme?.lowercased() else { return false }
            return scheme == "ws" || scheme == "wss"
        }
    }
}
