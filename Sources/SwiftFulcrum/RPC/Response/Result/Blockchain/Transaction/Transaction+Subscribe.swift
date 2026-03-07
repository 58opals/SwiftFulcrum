// Transaction+Subscribe.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct Subscribe: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let height: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw ResponseResultDecodeError.unexpectedFormat("Expected a height uint; got transaction hash and height array for Transaction.Subscribe: \(pairs.description)")
                    }
                }
            }
            

}
