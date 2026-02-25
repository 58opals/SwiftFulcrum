import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct ScriptHashModel {
            public struct GetBalanceModel: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetBalanceModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUseModel: JSONRPCResponse {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var isFound: Bool { blockHash != nil }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetFirstUseModel?
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
            
            public struct GetHistoryModel: JSONRPCResponse {
                public let transactions: [TransactionModel]
                public struct TransactionModel: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { TransactionModel(from: $0) }
                }
            }
            
            public struct GetMempoolModel: JSONRPCResponse {
                public let transactions: [TransactionModel]
                public struct TransactionModel: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { TransactionModel(from: $0) }
                }
            }
            
            public struct ListUnspentModel: JSONRPCResponse {
                public let items: [ItemModel]
                
                public struct ItemModel: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentItemModel) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { ItemModel(from: $0) }
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .scripthashAndStatus(let pair):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHashModel.SubscribeModel: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel
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
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
