// ServerCatalog+Repository.swift

import Foundation

extension SwiftFulcrum.ServerCatalog {
    public struct Repository: Sendable {
        let isBundledCatalogBacked: Bool
        private let loadCatalog: @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL]

        public init(load: @escaping @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL]) {
            self.init(load: load, isBundledCatalogBacked: false)
        }

        init(
            load: @escaping @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL],
            isBundledCatalogBacked: Bool
        ) {
            self.loadCatalog = load
            self.isBundledCatalogBacked = isBundledCatalogBacked
        }

        public func loadServers(
            for network: SwiftFulcrum.Client.Configuration.Network,
            fallback: [URL]
        ) async throws -> [URL] {
            try await loadCatalog(network, fallback)
        }
    }
}

extension SwiftFulcrum.ServerCatalog.Repository {
    public static let bundled = Self(load: { network, fallback in
        try BundledCatalogLoader.loadServers(for: network, fallback: fallback)
    }, isBundledCatalogBacked: true)

    public static func makeConstant(_ servers: [URL]) -> Self {
        let sanitizedServers = sanitizeServers(servers)
        return Self(load: { _, _ in
            try requireServers(sanitizedServers)
        }, isBundledCatalogBacked: false)
    }

    public static func sanitizeServers(_ servers: [URL]) -> [URL] {
        servers.compactMap { try? SwiftFulcrum.ServerCatalog.validate(endpoint: $0) }
    }

    static func requireServers(_ servers: [URL]) throws -> [URL] {
        guard !servers.isEmpty else {
            throw SwiftFulcrum.Client.Error.transport(.setupFailed)
        }
        return servers
    }
}
