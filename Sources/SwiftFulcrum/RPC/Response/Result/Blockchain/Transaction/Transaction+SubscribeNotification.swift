// Transaction+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct SubscribeNotification: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .transactionHashAndHeight(let pairs):
                        var hashValue: String?
                        var heightValue: UInt?
                        
                        for pair in pairs {
                            switch pair {
                            case .transactionHash(let transactionHash):
                                guard hashValue == nil else { throw ResponseResultDecodeError.unexpectedFormat("Duplicate transaction hash in notification payload") }
                                hashValue = transactionHash
                            case .height(let height):
                                guard heightValue == nil else { throw ResponseResultDecodeError.unexpectedFormat("Duplicate height in notification payload") }
                                heightValue = height
                            }
                        }
                        
                        guard let transactionHash = hashValue else { throw ResponseResultDecodeError.missingField("transactionHash") }
                        guard let height = heightValue else { throw ResponseResultDecodeError.missingField("height") }
                        
                        self.subscriptionIdentifier = transactionHash
                        self.transactionHash = transactionHash
                        self.height = height
                    case .height(let height):
                        throw ResponseResultDecodeError.unexpectedFormat("Expected [txid, height] for Transaction.Subscribe; got height only: \(height.description)")
                    }
                }
            }
            

}
