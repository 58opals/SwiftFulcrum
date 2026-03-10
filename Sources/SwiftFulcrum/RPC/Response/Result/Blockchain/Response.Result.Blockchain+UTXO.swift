// Response.Result.Blockchain+UTXO.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct UTXO {
        public struct GetInfo: Decodable, Sendable {
            public let confirmedHeight: UInt?
            public let scriptHash: String
            public let value: UInt
            public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.UTXO.GetInfo(from: decoder)
                self.confirmedHeight = payloadModel.confirmed_height
                self.scriptHash = payloadModel.scripthash
                self.value = payloadModel.value
                self.tokenData = payloadModel.token_data
            }
        }
    }
}
