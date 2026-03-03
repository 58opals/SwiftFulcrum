import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct GetHeight: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.GetHeight
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc
                }
            }
            

}
