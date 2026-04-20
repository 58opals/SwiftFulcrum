// Response.Error+Result.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Error {
    struct Result: Decodable, Sendable {
        let code: Int
        let message: String
    }
}
