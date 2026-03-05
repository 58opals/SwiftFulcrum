import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct IDFromPos: SwiftFulcrum.RPC.ResponseProtocol {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.IDFromPos
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            

}
