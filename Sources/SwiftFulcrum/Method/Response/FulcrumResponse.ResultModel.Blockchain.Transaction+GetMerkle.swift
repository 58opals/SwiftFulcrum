import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct GetMerkle: JSONRPCResponse {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.GetMerkle
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            

}
