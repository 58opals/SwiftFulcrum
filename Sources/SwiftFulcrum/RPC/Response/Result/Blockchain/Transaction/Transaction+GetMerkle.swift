import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct GetMerkle: SwiftFulcrum.RPC.ResponseProtocol {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            

}
