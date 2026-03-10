// Response.swift

import Foundation

extension SwiftFulcrum.RPC {
    public struct Response {
        struct Regular<Payload: Decodable> {
            let id: UUID
            let result: Payload
        }

        struct Subscription<Payload: Decodable> {
            let methodPath: String
            let result: Payload
        }

        struct Error: Decodable, Sendable {
            struct Result: Decodable, Sendable {
                let code: Int
                let message: String
            }

            let id: UUID
            let error: Result
        }
    }
}

extension SwiftFulcrum.RPC.Response {
    enum Kind<Payload: Decodable> {
        case empty(UUID)
        case regular(SwiftFulcrum.RPC.Response.Regular<Payload>)
        case subscription(SwiftFulcrum.RPC.Response.Subscription<Payload>)
        case error(SwiftFulcrum.RPC.Response.Error)
    }
    
    enum Identifier {
        case uuid(UUID)
        case string(String)
    }
}

extension SwiftFulcrum.RPC.Response.Identifier: Hashable, Sendable {}
extension SwiftFulcrum.RPC.Response.Regular: Sendable where Payload: Sendable {}
extension SwiftFulcrum.RPC.Response.Subscription: Sendable where Payload: Sendable {}
extension SwiftFulcrum.RPC.Response.Kind: Sendable where Payload: Sendable {}
