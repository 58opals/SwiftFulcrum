import Foundation

extension FulcrumResponse.JSONRPCModel.Result.Blockchain {
    public struct UTXO {
        public struct GetInfo: Decodable, Sendable {
            public let confirmed_height: UInt?
            public let scripthash: String
            public let value: UInt
            public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokens.JSON?
        }
    }
}
