// ServerCatalog~EndpointValidation.swift

import Foundation

extension SwiftFulcrum.ServerCatalog {
    static func validate(endpoint: URL) throws -> URL {
        guard ["ws", "wss"].contains(endpoint.scheme?.lowercased()),
              let host = endpoint.host,
              !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              endpoint.user == nil,
              endpoint.password == nil,
              endpoint.fragment == nil,
              endpoint.port.map({ (1 ... 65_535).contains($0) }) ?? true else {
            throw SwiftFulcrum.Client.Error.client(.invalidURL("Invalid WebSocket endpoint URL"))
        }

        return endpoint
    }
}
