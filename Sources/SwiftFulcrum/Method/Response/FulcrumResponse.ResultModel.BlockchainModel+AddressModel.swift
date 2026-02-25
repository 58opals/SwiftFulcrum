import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct AddressModel {
            public struct GetBalanceModel: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetBalanceModel
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
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetFirstUseModel?
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetHistoryItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetHistoryModel
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetMempoolItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetMempoolModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { TransactionModel(from: $0) }
                }
            }
            
            public struct GetScriptHashModel: JSONRPCResponse {
                public let scriptHash: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetScriptHashModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.scriptHash = jsonrpc
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
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.ListUnspentItemModel) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.ListUnspentModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { ItemModel(from: $0) }
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.SubscribeModel?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .addressAndStatus(let pair):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected a status string; got address and status array for AddressModel.SubscribeModel: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.SubscribeModel
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
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}
