import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct Unsubscribe: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
            

}
