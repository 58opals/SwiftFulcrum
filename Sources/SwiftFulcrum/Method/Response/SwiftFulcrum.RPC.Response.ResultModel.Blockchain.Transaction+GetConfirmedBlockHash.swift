import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct GetConfirmedBlockHash: SwiftFulcrum.RPC.ResponseProtocol {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.GetConfirmedBlockHash
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            

}
