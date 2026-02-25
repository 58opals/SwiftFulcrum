import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct SubscribeModel: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a height uint; got transaction hash and height array for TransactionModel.SubscribeModel: \(pairs.description)")
                    }
                }
            }
            

}
