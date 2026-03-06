import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    public struct UTXO {
        public struct GetInfo: Decodable, Sendable {
            public let confirmed_height: UInt?
            public let scripthash: String
            public let value: UInt
            public let token_data: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
        }
    }
}
