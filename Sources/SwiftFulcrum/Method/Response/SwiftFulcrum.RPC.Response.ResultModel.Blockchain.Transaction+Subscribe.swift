import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
            public struct Subscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Expected a height uint; got transaction hash and height array for Transaction.Subscribe: \(pairs.description)")
                    }
                }
            }
            

}
