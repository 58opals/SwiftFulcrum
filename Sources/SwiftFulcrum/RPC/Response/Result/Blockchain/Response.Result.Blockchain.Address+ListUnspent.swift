// Response.Result.Blockchain.Address+ListUnspent.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct ListUnspent: Decodable, Sendable {
        public let items: [Item]

        public init(from decoder: Decoder) throws {
            let payloadModel = try [SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.ListUnspentItem](from: decoder)
            self.items = payloadModel.map(Item.init(from:))
        }
    }
}
