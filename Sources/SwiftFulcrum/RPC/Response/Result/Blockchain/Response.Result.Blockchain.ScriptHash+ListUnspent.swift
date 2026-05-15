// Response.Result.Blockchain.ScriptHash+ListUnspent.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct ListUnspent: Decodable, Sendable {
        public let items: [Item]

        public init(from decoder: Decoder) throws {
            let payloadModel = try [SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem](from: decoder)
            self.items = try payloadModel.map(Item.init(from:))
        }
    }
}
