// Response+Identifier.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    enum Identifier {
        case uuid(UUID)
        case string(String)
    }
}

extension SwiftFulcrum.RPC.Response.Identifier: Hashable, Sendable {}
