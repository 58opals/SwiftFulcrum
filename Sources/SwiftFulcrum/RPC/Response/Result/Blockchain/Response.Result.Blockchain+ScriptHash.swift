// Response.Result.Blockchain+ScriptHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
        public struct ScriptHash {
            public struct GetBalance: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetBalance
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUse: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var isFound: Bool { blockHash != nil }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetFirstUse?
                public init(fromRPC jsonrpc: JSONRPC) {
                    guard let json = jsonrpc else {
                        self.blockHash = nil
                        self.height = nil
                        self.transactionHash = nil
                        return
                    }
                    self.blockHash = json.block_hash
                    self.height = json.height
                    self.transactionHash = json.tx_hash
                }
            }
            
            public struct GetHistory: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistory
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetMempool: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempool
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct ListUnspent: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let items: [Item]
                
                public struct Item: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspent
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let status: String?
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe?
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .scripthashAndStatus(let pair):
                        throw ResponseResultDecodeError.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHash.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .scripthashAndStatus(let pair):
                        guard let first = pair.first, let scripthash = first else { throw ResponseResultDecodeError.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = scripthash
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw ResponseResultDecodeError.unexpectedFormat("Expected scripthash and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct Unsubscribe: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
                public let isSuccess: Bool
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
