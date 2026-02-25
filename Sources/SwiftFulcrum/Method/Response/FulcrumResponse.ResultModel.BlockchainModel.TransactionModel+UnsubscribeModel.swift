import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
            

}
