// Response+Subscription.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    struct Subscription<Payload: Decodable> {
        let methodPath: String
        let result: Payload
    }
}

extension SwiftFulcrum.RPC.Response.Subscription: Sendable where Payload: Sendable {}
