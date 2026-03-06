import Foundation

public extension SwiftFulcrum.ServerCatalog {
    struct Repository: Sendable {
        enum Kind { case bundled, constant, custom }

        private let kind: Kind
        private let loadCatalog: @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL]

        public init(load: @escaping @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL]) {
            self.init(load: load, kind: .custom)
        }

        init(load: @escaping @Sendable (SwiftFulcrum.Client.Configuration.Network, [URL]) async throws -> [URL], kind: Kind) {
            self.loadCatalog = load
            self.kind = kind
        }

        public func loadServers(
            for network: SwiftFulcrum.Client.Configuration.Network,
            fallback: [URL]
        ) async throws -> [URL] {
            try await loadCatalog(network, fallback)
        }

        var isBundled: Bool { kind == .bundled }
    }
}

public extension SwiftFulcrum.ServerCatalog.Repository {
    static let bundled = Self(load: { network, fallback in
        try await Task.detached(priority: .utility) {
            if let bundled = try? WebSocketModel.Server.decodeBundledServers(for: network), !bundled.isEmpty {
                return bundled
            }

            let sanitizedFallback = sanitizeServers(fallback)
            guard !sanitizedFallback.isEmpty else { throw SwiftFulcrum.Client.Error.transport(.setupFailed) }
            return sanitizedFallback
        }.value
    }, kind: .bundled)

    static func makeConstant(_ servers: [URL]) -> Self {
        Self(load: { _, _ in
            let sanitizedServers = sanitizeServers(servers)
            guard !sanitizedServers.isEmpty else {
                throw SwiftFulcrum.Client.Error.transport(.setupFailed)
            }
            return sanitizedServers
        }, kind: .constant)
    }

    static func sanitizeServers(_ servers: [URL]) -> [URL] {
        servers.filter { server in
            guard let scheme = server.scheme?.lowercased() else { return false }
            return scheme == "ws" || scheme == "wss"
        }
    }
}
