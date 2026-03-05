// FulcrumServerCatalogRepository.swift

import Foundation

@available(*, deprecated, message: "Use SwiftFulcrum.ServerCatalog.Repository instead.")
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
            if let bundled = try? WebSocketModel.Server.decodeBundledServers(for: network), !bundled.isEmpty {
                return bundled
            }

            let sanitizedFallback = sanitizeServers(fallback)
            guard !sanitizedFallback.isEmpty else { throw FulcrumClient.Error.transport(.setupFailed) }
            return sanitizedFallback
        }.value
    }, kind: .bundled)

    public static func makeConstant(_ servers: [URL]) -> Self {
        Self(load: { _, _ in
            let sanitizedServers = sanitizeServers(servers)
            guard !sanitizedServers.isEmpty else {
                throw FulcrumClient.Error.transport(.setupFailed)
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
