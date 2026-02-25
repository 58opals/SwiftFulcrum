import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct GetMerkleModel: JSONRPCResponse {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetMerkleModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            

}
