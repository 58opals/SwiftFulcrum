import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
    public struct UTXOModel {
        public struct GetInfoModel: JSONRPCResponse {
            public let confirmedHeight: UInt?
            public let scriptHash: String
            public let value: UInt
            public let tokenData: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.UTXOModel.GetInfoModel

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.confirmedHeight = jsonrpc.confirmed_height
                self.scriptHash = jsonrpc.scripthash
                self.value = jsonrpc.value
                self.tokenData = jsonrpc.token_data
            }
        }
    }
}
