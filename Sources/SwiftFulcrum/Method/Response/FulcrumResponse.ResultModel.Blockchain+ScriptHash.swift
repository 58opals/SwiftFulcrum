import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
        public struct ScriptHash {
            public struct GetBalance: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetBalance
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUse: JSONRPCResponse {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var isFound: Bool { blockHash != nil }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetFirstUse?
                public init(fromRPC jsonrpc: JSONRPCModel) {
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
            
            public struct GetHistory: JSONRPCResponse {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetHistory
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetMempool: JSONRPCResponse {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.GetMempool
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct ListUnspent: JSONRPCResponse {
                public let items: [Item]
                
                public struct Item: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: FulcrumMethodRequest.BlockchainModel.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.ListUnspent
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.Subscribe?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .scripthashAndStatus(let pair):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHash.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .scripthashAndStatus(let pair):
                        guard let first = pair.first, let scripthash = first else { throw FulcrumResponse.ResultModel.Error.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = scripthash
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected scripthash and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct Unsubscribe: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.ScriptHash.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
