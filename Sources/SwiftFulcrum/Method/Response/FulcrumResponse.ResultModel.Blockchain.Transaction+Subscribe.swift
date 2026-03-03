import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct Subscribe: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a height uint; got transaction hash and height array for Transaction.Subscribe: \(pairs.description)")
                    }
                }
            }
            

}
