import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
        public struct Address {
            public struct GetBalance: SwiftFulcrum.RPC.ResponseProtocol {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetBalance
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUse: SwiftFulcrum.RPC.ResponseProtocol {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var isFound: Bool { blockHash != nil }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetFirstUse?
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
            
            public struct GetHistory: SwiftFulcrum.RPC.ResponseProtocol {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetHistory
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetMempool: SwiftFulcrum.RPC.ResponseProtocol {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempool
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetScriptHash: SwiftFulcrum.RPC.ResponseProtocol {
                public let scriptHash: String
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetScriptHash
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.scriptHash = jsonrpc
                }
            }
            
            public struct ListUnspent: SwiftFulcrum.RPC.ResponseProtocol {
                public let items: [Item]
                
                public struct Item: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.ListUnspent
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let status: String?
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe?
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .addressAndStatus(let pair):
                        throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Expected a status string; got address and status array for Address.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: SwiftFulcrum.RPC.ResponseProtocol {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .addressAndStatus(let pair):
                        guard let first = pair.first, let address = first else { throw SwiftFulcrum.RPC.Response.Result.Error.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = address
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Expected address and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct Unsubscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let isSuccess: Bool
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
