import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct IDFromPosModel: JSONRPCResponse {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.IDFromPosModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            

}
