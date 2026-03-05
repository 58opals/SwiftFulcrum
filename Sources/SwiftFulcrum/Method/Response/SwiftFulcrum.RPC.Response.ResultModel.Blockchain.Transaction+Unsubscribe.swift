import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct Unsubscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
            

}
