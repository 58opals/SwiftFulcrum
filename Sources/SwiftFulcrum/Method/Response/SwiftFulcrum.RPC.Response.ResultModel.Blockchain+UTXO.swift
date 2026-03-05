import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain {
    public struct UTXO {
        public struct GetInfo: SwiftFulcrum.RPC.ResponseProtocol {
            public let confirmedHeight: UInt?
            public let scriptHash: String
            public let value: UInt
            public let tokenData: SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens.JSON?

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.UTXO.GetInfo

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.confirmedHeight = jsonrpc.confirmed_height
                self.scriptHash = jsonrpc.scripthash
                self.value = jsonrpc.value
                self.tokenData = jsonrpc.token_data
            }
        }
    }
}
