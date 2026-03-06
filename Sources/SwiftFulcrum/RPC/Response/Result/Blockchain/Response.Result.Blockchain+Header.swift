// Response.Result.Blockchain+Header.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
        public struct Header {
            public struct Get: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Header.Get
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        

}
