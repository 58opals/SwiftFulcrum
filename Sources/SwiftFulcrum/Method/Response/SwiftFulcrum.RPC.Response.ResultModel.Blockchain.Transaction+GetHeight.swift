import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct GetHeight: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.GetHeight
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc
                }
            }
            

}
