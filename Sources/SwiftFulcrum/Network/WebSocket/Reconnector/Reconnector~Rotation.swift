// Reconnector~Rotation.swift

import Foundation

extension WebSocketConnection.Reconnector {
    func buildCandidateRotation(preferredURL: URL?, currentURL: URL) async throws -> [URL] {
        var fallbacks = [currentURL]
        if let preferredURL { fallbacks.append(preferredURL) }
        fallbacks.append(contentsOf: bootstrapServers)
        fallbacks = Self.deduplicate(fallbacks)

        if serverCatalog.isEmpty {
            serverCatalog = Self.makeValidatedUniqueServers(
                try await serverCatalogLoader.loadServers(for: network, fallback: fallbacks)
            )
        } else {
            serverCatalog = Self.makeValidatedUniqueServers(serverCatalog + fallbacks)
        }

        guard !serverCatalog.isEmpty else { return [currentURL] }

        var rotation = Self.rotate(serverCatalog, offset: nextServerIndex)
        let currentKey = Self.canonicalize(currentURL)

        if rotation.count > 1 {
            rotation.removeAll { Self.canonicalize($0) == currentKey }
        }

        if let preferredURL {
            let preferredKey = Self.canonicalize(preferredURL)
            rotation.removeAll { Self.canonicalize($0) == preferredKey }
            rotation.insert(preferredURL, at: 0)
        }

        if !rotation.contains(where: { Self.canonicalize($0) == currentKey }) {
            rotation.append(currentURL)
        }

        return rotation
    }

    func indexOfServer(_ url: URL) -> Int? {
        let key = Self.canonicalize(url)
        return serverCatalog.firstIndex { Self.canonicalize($0) == key }
    }

    static func canonicalize(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        if components.path == "/" {
            components.path = ""
        }
        return components.url?.absoluteString ?? url.absoluteString
    }

    static func deduplicate(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        var unique: [URL] = .init()
        unique.reserveCapacity(urls.count)

        for url in urls {
            let key = canonicalize(url)
            if seen.insert(key).inserted {
                unique.append(url)
            }
        }

        return unique
    }

    static func makeValidatedUniqueServers(_ urls: [URL]) -> [URL] {
        deduplicate(SwiftFulcrum.ServerCatalog.Repository.sanitizeServers(urls))
    }

    static func rotate(_ urls: [URL], offset: Int) -> [URL] {
        guard !urls.isEmpty else { return urls }
        let normalizedOffset = ((offset % urls.count) + urls.count) % urls.count
        guard normalizedOffset != 0 else { return urls }
        return Array(urls[normalizedOffset...] + urls[..<normalizedOffset])
    }
}
