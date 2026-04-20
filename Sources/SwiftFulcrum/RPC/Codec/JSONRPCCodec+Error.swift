// JSONRPCCodec+Error.swift

import Foundation

extension JSONRPCCodec {
    enum Error: Swift.Error {
        case rpc(SwiftFulcrum.RPC.Response.Error, methodPath: MethodPath, description: String)
        case storage(StorageIssue, description: String)
        case decodingFailure(reason: DecodingFailureReason, data: Data?, description: String)
    }
}
