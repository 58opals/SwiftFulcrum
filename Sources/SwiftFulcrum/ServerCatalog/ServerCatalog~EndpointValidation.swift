// ServerCatalog~EndpointValidation.swift

import Foundation

extension SwiftFulcrum.ServerCatalog {
    static func validate(endpoint: URL) throws -> URL {
        guard ["ws", "wss"].contains(endpoint.scheme?.lowercased()),
              let host = endpoint.host,
              !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              endpoint.port.map({ (1 ... 65_535).contains($0) }) ?? true else {
            throw SwiftFulcrum.Client.Error.client(.invalidURL(endpoint.absoluteString))
        }

        return endpoint
    }
}
