// ServerCatalog.Repository+BundledLoader.swift

import Foundation

extension SwiftFulcrum.ServerCatalog.Repository {
    actor BundledCatalogLoader {
        static let shared = BundledCatalogLoader()

        func loadServers(
            for network: SwiftFulcrum.Client.Configuration.Network,
            fallback: [URL]
        ) throws -> [URL] {
            if let bundled = try? WebSocketConnection.Server.decodeBundledServers(for: network), !bundled.isEmpty {
                return bundled
            }

            let sanitizedFallback = SwiftFulcrum.ServerCatalog.Repository.sanitizeServers(fallback)
            guard !sanitizedFallback.isEmpty else {
                throw SwiftFulcrum.Client.Error.transport(.setupFailed)
            }
            return sanitizedFallback
        }
    }
}
