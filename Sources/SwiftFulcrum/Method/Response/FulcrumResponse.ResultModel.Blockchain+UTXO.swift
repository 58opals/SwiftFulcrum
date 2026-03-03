import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
    public struct UTXO {
        public struct GetInfo: JSONRPCResponse {
            public let confirmedHeight: UInt?
            public let scriptHash: String
            public let value: UInt
            public let tokenData: FulcrumMethodRequest.BlockchainModel.CashTokens.JSON?

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.UTXO.GetInfo

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.confirmedHeight = jsonrpc.confirmed_height
                self.scriptHash = jsonrpc.scripthash
                self.value = jsonrpc.value
                self.tokenData = jsonrpc.token_data
            }
        }
    }
}
