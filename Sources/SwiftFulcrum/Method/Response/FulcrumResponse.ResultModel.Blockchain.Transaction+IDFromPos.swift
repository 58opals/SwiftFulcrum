import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct IDFromPos: JSONRPCResponse {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.IDFromPos
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            

}
