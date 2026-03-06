import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct IDFromPos: SwiftFulcrum.RPC.ResponseProtocol {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            

}
