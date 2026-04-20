// Response+Kind.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    enum Kind<Payload: Decodable> {
        case empty(UUID)
        case regular(SwiftFulcrum.RPC.Response.Regular<Payload>)
        case subscription(SwiftFulcrum.RPC.Response.Subscription<Payload>)
        case error(SwiftFulcrum.RPC.Response.Error)
    }
}

extension SwiftFulcrum.RPC.Response.Kind: Sendable where Payload: Sendable {}
