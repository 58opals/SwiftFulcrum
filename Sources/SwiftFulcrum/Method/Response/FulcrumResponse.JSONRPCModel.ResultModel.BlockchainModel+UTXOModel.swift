import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
    public struct UTXOModel {
        public struct GetInfoModel: Decodable, Sendable {
            public let confirmed_height: UInt?
            public let scripthash: String
            public let value: UInt
            public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
        }
    }
}
