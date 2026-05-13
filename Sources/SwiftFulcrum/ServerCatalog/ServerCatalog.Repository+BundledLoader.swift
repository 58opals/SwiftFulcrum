// ServerCatalog.Repository+BundledLoader.swift

import Foundation

extension SwiftFulcrum.ServerCatalog.Repository {
    enum BundledCatalogLoader {
        static func loadServers(
            for network: SwiftFulcrum.Client.Configuration.Network,
            fallback: [URL]
        ) throws -> [URL] {
            if let bundled = try? WebSocketConnection.Server.decodeBundledServers(for: network), !bundled.isEmpty {
                return bundled
            }

            return try SwiftFulcrum.ServerCatalog.Repository.requireServers(
                SwiftFulcrum.ServerCatalog.Repository.sanitizeServers(fallback)
            )
        }
    }
}
