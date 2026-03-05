import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct GetMerkle: SwiftFulcrum.RPC.ResponseProtocol {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.GetMerkle
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            

}
