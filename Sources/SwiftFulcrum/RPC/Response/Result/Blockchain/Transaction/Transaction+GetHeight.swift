import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct GetHeight: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetHeight
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc
                }
            }
            

}
