// Transaction+GetHeight.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct GetHeight: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let height: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.GetHeight
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc
                }
            }
            

}
