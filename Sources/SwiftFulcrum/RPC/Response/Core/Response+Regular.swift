// Response+Regular.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    struct Regular<Payload: Decodable> {
        let id: UUID
        let result: Payload
    }
}

extension SwiftFulcrum.RPC.Response.Regular: Sendable where Payload: Sendable {}
