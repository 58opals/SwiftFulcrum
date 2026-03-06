import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct Unsubscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let isSuccess: Bool
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.isSuccess = jsonrpc
                }
            }
            

}
