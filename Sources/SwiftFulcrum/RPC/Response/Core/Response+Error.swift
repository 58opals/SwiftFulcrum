// Response+Error.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    struct Error: Decodable, Sendable {
        let id: UUID
        let error: Result
    }
}
