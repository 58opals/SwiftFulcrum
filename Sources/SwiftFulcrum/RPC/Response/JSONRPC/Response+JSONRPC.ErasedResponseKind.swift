// Response+JSONRPC.ErasedResponseKind.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC {
    enum ErasedResponseKind: Sendable {
        case regular(UUID)
        case error(SwiftFulcrum.Client.Error)
        case empty(UUID?)
    }
}
