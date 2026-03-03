import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct GetConfirmedBlockHash: JSONRPCResponse {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.GetConfirmedBlockHash
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            

}
