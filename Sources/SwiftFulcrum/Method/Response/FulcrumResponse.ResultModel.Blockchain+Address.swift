import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
        public struct Address {
            public struct GetBalance: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetBalance
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
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetFirstUse?
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetHistory
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetMempool
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetScriptHash: JSONRPCResponse {
                public let scriptHash: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.GetScriptHash
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.scriptHash = jsonrpc
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.ListUnspent
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.Subscribe?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .addressAndStatus(let pair):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a status string; got address and status array for Address.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .addressAndStatus(let pair):
                        guard let first = pair.first, let address = first else { throw FulcrumResponse.ResultModel.Error.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = address
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected address and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct Unsubscribe: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
