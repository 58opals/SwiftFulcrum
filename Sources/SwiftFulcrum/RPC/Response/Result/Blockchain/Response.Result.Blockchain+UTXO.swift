// Response.Result.Blockchain+UTXO.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct UTXO {
        public struct GetInfo: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let confirmedHeight: UInt?
            public let scriptHash: String
            public let value: UInt
            public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.UTXO.GetInfo

            public init(fromRPC jsonrpc: JSONRPC) {
                self.confirmedHeight = jsonrpc.confirmed_height
                self.scriptHash = jsonrpc.scripthash
                self.value = jsonrpc.value
                self.tokenData = jsonrpc.token_data
            }
        }
    }
}
