import Foundation
import SwiftFulcrum

enum TestEndpointPolicy {
    private static let fixedServerURLKey = "SWIFTFULCRUM_TEST_SERVER_URL"

    static func resolveServerURL(
        network: SwiftFulcrum.Client.Configuration.Network = .mainnet
    ) async throws -> URL {
        let environment = ProcessInfo.processInfo.environment

        if
            let configuredURL = environment[fixedServerURLKey],
            !configuredURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            guard
                let url = URL(string: configuredURL),
                isWebSocketURL(url)
            else {
                throw SwiftFulcrum.Client.Error.client(.invalidURL(configuredURL))
            }
            return url
        }

        let bundledServers = try await SwiftFulcrum.ServerCatalog.Repository.bundled.loadServers(
            for: network,
            fallback: .init()
        )
        let sanitizedServers = bundledServers.filter { server in
            guard let scheme = server.scheme?.lowercased() else { return false }
            return scheme == "ws" || scheme == "wss"
        }
        guard let endpoint = sanitizedServers.first else {
            throw SwiftFulcrum.Client.Error.transport(.setupFailed)
        }
        return endpoint
    }

    private static func isWebSocketURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "ws" || scheme == "wss"
    }
}
