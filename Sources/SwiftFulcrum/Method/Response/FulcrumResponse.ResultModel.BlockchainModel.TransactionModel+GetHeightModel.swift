import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct GetHeightModel: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetHeightModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc
                }
            }
            

}
