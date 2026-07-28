// Client+Configuration.swift

import Foundation

extension SwiftFulcrum.Client {
    public struct Configuration: Sendable {
        public var reconnect: ReconnectPolicy
        public var connectionTimeout: TimeInterval
        public var maximumMessageSize: Int
        public var bootstrapServers: [URL]?
        public var serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository
        public var network: Network
        public var protocolNegotiation: ProtocolNegotiation

        public static let basic = Configuration()

        public init(
            reconnect: ReconnectPolicy = .basic,
            connectionTimeout: TimeInterval = 10,
            maximumMessageSize: Int = 64 * 1024 * 1024,
            bootstrapServers: [URL]? = nil,
            serverCatalogLoader: SwiftFulcrum.ServerCatalog.Repository = .bundled,
            network: Network = .mainnet,
            protocolNegotiation: ProtocolNegotiation = .init()
        ) {
            self.reconnect = reconnect
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
    static let maximumScheduledIntervalSeconds: TimeInterval = 365 * 24 * 60 * 60

    func validate() throws {
        try validateDuration(connectionTimeout, named: "connectionTimeout")

        guard maximumMessageSize > 0 else {
            throw SwiftFulcrum.Client.Error.client(
                .invalidConfiguration("maximumMessageSize must be greater than zero.")
            )
        }

        try validateDuration(reconnect.reconnectionDelay, named: "reconnect.reconnectionDelay")
        try validateDuration(reconnect.maximumDelay, named: "reconnect.maximumDelay")

        let jitterRange = reconnect.jitterRange
        guard jitterRange.lowerBound.isFinite,
              jitterRange.upperBound.isFinite,
              jitterRange.lowerBound >= 0,
              jitterRange.upperBound >= 0 else {
            throw SwiftFulcrum.Client.Error.client(
                .invalidConfiguration("reconnect.jitterRange bounds must be finite and nonnegative.")
            )
        }
    }

    func convertToWebSocketConfiguration() -> WebSocketConnection.Configuration {
        return WebSocketConnection.Configuration(
            maximumMessageSize: maximumMessageSize,
            bootstrapServers: bootstrapServers ?? .init(),
            serverCatalogLoader: serverCatalogLoader,
            network: network
        )
    }

    private func validateDuration(_ value: TimeInterval, named name: String) throws {
        guard value.isFinite,
              value >= 0,
              value <= Self.maximumScheduledIntervalSeconds else {
            throw SwiftFulcrum.Client.Error.client(
                .invalidConfiguration(
                    "\(name) must be finite and between zero and "
                        + "\(Self.maximumScheduledIntervalSeconds) seconds."
                )
            )
        }
    }
}
