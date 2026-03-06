// Response.Result.Blockchain+EstimateFee.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
        public struct EstimateFee: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let fee: Double
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.EstimateFee
            public init(fromRPC jsonrpc: JSONRPC) {
                self.fee = jsonrpc
            }
        }
        

}
