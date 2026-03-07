// Response.Result.Blockchain+RelayFee.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
        public struct RelayFee: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let fee: Double
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.RelayFee
            public init(fromRPC jsonrpc: JSONRPC) {
                self.fee = jsonrpc
            }
        }
        

}
