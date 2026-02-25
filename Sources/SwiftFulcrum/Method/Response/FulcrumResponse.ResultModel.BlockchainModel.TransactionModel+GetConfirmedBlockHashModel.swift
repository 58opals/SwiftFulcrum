import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct GetConfirmedBlockHashModel: JSONRPCResponse {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetConfirmedBlockHashModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            

}
