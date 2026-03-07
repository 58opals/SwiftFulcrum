// Transaction+GetConfirmedBlockHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct GetConfirmedBlockHash: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            

}
