// Response.Result.Blockchain.ScriptHash+GetBalance.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash {
    public struct GetBalance: Decodable, Sendable {
        public let confirmed: UInt64
        public let unconfirmed: Int64

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetBalance(from: decoder)
            self.confirmed = payloadModel.confirmed
            self.unconfirmed = payloadModel.unconfirmed
        }
    }
}
