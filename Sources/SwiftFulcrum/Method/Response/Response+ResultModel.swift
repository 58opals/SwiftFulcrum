// Response+ResultModel.swift

import Foundation

extension Response { public struct ResultModel {} }

extension Response.ResultModel {
    public struct ServerModel {
        public struct PingModel: JSONRPCResponse {
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.ServerModel.PingModel?
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard jsonrpc == nil else {
                    throw Response.ResultModel.Error.unexpectedFormat("Expected null result for server.ping().")
                }
            }
        }
        
        public struct VersionModel: JSONRPCResponse {
            public let serverVersion: String
            public let negotiatedProtocolVersion: ProtocolVersionModel
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.ServerModel.VersionModel
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard let protocolVersion = ProtocolVersionModel(string: jsonrpc.protocolVersion) else {
                    throw Error.unexpectedFormat("Negotiated protocol version is invalid: \(jsonrpc.protocolVersion)")
                }
                
                self.serverVersion = jsonrpc.serverVersion
                self.negotiatedProtocolVersion = protocolVersion
            }
        }
        
        public struct FeaturesModel: JSONRPCResponse {
            public let genesisHash: String
            public let hashFunction: String
            public let serverVersion: String
            public let minimumProtocolVersion: ProtocolVersionModel
            public let maximumProtocolVersion: ProtocolVersionModel
            public let pruningLimit: Int?
            public let hosts: [String: HostModel]?
            public let hasDoubleSpendProofs: Bool?
            public let hasCashTokens: Bool?
            public let reusablePaymentAddress: ReusablePaymentAddressModel?
            public let hasBroadcastPackageSupport: Bool?
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.ServerModel.FeaturesModel
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard let minVersion = ProtocolVersionModel(string: jsonrpc.protocol_min) else {
                    throw Error.unexpectedFormat("Minimum protocol version is invalid: \(jsonrpc.protocol_min)")
                }
                guard let maxVersion = ProtocolVersionModel(string: jsonrpc.protocol_max) else {
                    throw Error.unexpectedFormat("Maximum protocol version is invalid: \(jsonrpc.protocol_max)")
                }
                
                self.genesisHash = jsonrpc.genesis_hash
                self.hashFunction = jsonrpc.hash_function
                self.serverVersion = jsonrpc.server_version
                self.minimumProtocolVersion = minVersion
                self.maximumProtocolVersion = maxVersion
                self.pruningLimit = jsonrpc.pruning
                self.hosts = jsonrpc.hosts?.mapValues { HostModel(from: $0) }
                self.hasDoubleSpendProofs = jsonrpc.dsproof
                self.hasCashTokens = jsonrpc.cashtokens
                self.reusablePaymentAddress = jsonrpc.rpa.map(ReusablePaymentAddressModel.init(from:))
                self.hasBroadcastPackageSupport = jsonrpc.broadcast_package
            }
            
            public struct HostModel: Decodable, Sendable {
                public let sslPort: Int?
                public let tcpPort: Int?
                public let webSocketPort: Int?
                public let secureWebSocketPort: Int?
                
                init(from json: JSONRPCModel.HostModel) {
                    self.sslPort = json.ssl_port
                    self.tcpPort = json.tcp_port
                    self.webSocketPort = json.ws_port
                    self.secureWebSocketPort = json.wss_port
                }
            }
            
            public struct ReusablePaymentAddressModel: Decodable, Sendable {
                public let historyBlockLimit: Int?
                public let maximumHistoryItems: Int?
                public let indexedPrefixBits: Int?
                public let minimumPrefixBits: Int?
                public let startingHeight: Int?
                
                init(from json: JSONRPCModel.ReusablePaymentAddressModel) {
                    self.historyBlockLimit = json.history_block_limit
                    self.maximumHistoryItems = json.max_history
                    self.indexedPrefixBits = json.prefix_bits
                    self.minimumPrefixBits = json.prefix_bits_min
                    self.startingHeight = json.starting_height
                }
            }
        }
    }
    
    public struct BlockchainModel {
        public struct EstimateFeeModel: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.EstimateFeeModel
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        
        public struct RelayFeeModel: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.RelayFeeModel
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        
        public struct ScriptHashModel {
            public struct GetBalanceModel: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetBalanceModel
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
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetFirstUseModel?
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryModel
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolModel
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentItemModel) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { ItemModel(from: $0) }
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .scripthashAndStatus(let pair):
                        throw Error.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHashModel.SubscribeModel: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .scripthashAndStatus(let pair):
                        guard let first = pair.first, let scripthash = first else { throw Error.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = scripthash
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw Error.unexpectedFormat("Expected scripthash and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.ScriptHashModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        
        public struct AddressModel {
            public struct GetBalanceModel: JSONRPCResponse {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetBalanceModel
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
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetFirstUseModel?
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetHistoryItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetHistoryModel
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetMempoolItemModel) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetMempoolModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.transactions = jsonrpc.map { TransactionModel(from: $0) }
                }
            }
            
            public struct GetScriptHashModel: JSONRPCResponse {
                public let scriptHash: String
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.GetScriptHashModel
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
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.ListUnspentItemModel) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.ListUnspentModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.items = jsonrpc.map { ItemModel(from: $0) }
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let status: String?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.SubscribeModel?
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .addressAndStatus(let pair):
                        throw Error.unexpectedFormat("Expected a status string; got address and status array for AddressModel.SubscribeModel: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .addressAndStatus(let pair):
                        guard let first = pair.first, let address = first else { throw Error.missingField("subscriptionIdentifier") }
                        self.subscriptionIdentifier = address
                        self.status = (pair.count > 1) ? pair[1] : nil
                    case .status(let statusString):
                        throw Error.unexpectedFormat("Expected address and status pair; got single status: \(statusString)")
                    }
                }
            }
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.AddressModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        
        public struct BlockModel {
            public struct HeaderModel: JSONRPCResponse {
                public let hex: String
                public let proof: ProofModel?
                
                public struct ProofModel: Decodable, Sendable {
                    public let branch: [String]
                    public let root: String
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.BlockModel.HeaderModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    switch jsonrpc {
                    case .raw(let raw):
                        self.hex = raw
                        self.proof = nil
                    case .proof(let proof):
                        self.hex = proof.header
                        self.proof = ProofModel(branch: proof.branch,
                                           root: proof.root)
                    }
                }
            }
            
            public struct HeadersModel: JSONRPCResponse {
                public let count: UInt
                public let headers: [String]
                public let hex: String
                public let max: UInt
                public let proof: BlockModel.HeaderModel.ProofModel?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.BlockModel.HeadersModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.count = jsonrpc.count
                    self.hex = jsonrpc.hex
                    self.headers = jsonrpc.headers ?? Self.splitHeaders(hex: jsonrpc.hex)
                    self.max = jsonrpc.max
                    self.proof = {
                        guard let branch = jsonrpc.branch,
                              let root = jsonrpc.root else {
                            return nil
                        }
                        
                        return BlockModel.HeaderModel.ProofModel(branch: branch, root: root)
                    }()
                }
                
                private static func splitHeaders(hex: String) -> [String] {
                    
                    let headerCharacterLength = 160
                    var headers: [String] = .init()
                    var currentIndex = hex.startIndex
                    
                    while currentIndex < hex.endIndex {
                        guard let endIndex = hex.index(currentIndex,
                                                       offsetBy: headerCharacterLength,
                                                       limitedBy: hex.endIndex) else {
                            break
                        }
                        
                        guard hex.distance(from: currentIndex, to: endIndex) == headerCharacterLength else {
                            break
                        }
                        
                        headers.append(String(hex[currentIndex..<endIndex]))
                        currentIndex = endIndex
                    }
                    
                    return headers
                }
            }
        }
        
        public struct HeaderModel {
            public struct GetModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.HeaderModel.GetModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        
        public struct HeadersModel {
            public struct GetTipModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.GetTipModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .topHeader(let tip):
                        self.height = tip.height
                        self.hex = tip.hex
                    case .newHeader(let batch) where batch.count == 1:
                        self.height = batch[0].height
                        self.hex = batch[0].hex
                    case .newHeader(let batch):
                        throw Response.ResultModel.Error.unexpectedFormat("Expected single top header; received batch of new headers: \(batch.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let blocks: [BlockModel]
                
                public struct BlockModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    self.subscriptionIdentifier = FulcrumMethodRequest.blockchain(.headers(.subscribe)).path
                    
                    switch jsonrpc {
                    case .newHeader(let list):
                        guard !list.isEmpty else { throw Error.missingField("header list empty") }
                        self.blocks = list.map { BlockModel(height: $0.height, hex: $0.hex) }
                    case .topHeader(let tip):
                        self.blocks = [BlockModel(height: tip.height, hex: tip.hex)]
                    }
                }
            }
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        
        public struct TransactionModel {
            public struct BroadcastModel: JSONRPCResponse {
                public let transactionHash: Data
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.BroadcastModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    self.transactionHash = try Self.decodeHex(jsonrpc)
                }
                
                private static func decodeHex(_ hex: String) throws -> Data {
                    let string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard string.count % 2 == 0 else {
                        throw Response.ResultModel.Error.unexpectedFormat("txid has odd hex length: \(string.count)")
                    }
                    var data = Data(); data.reserveCapacity(string.count / 2)
                    var index = string.startIndex
                    while index < string.endIndex {
                        let currentIndex = string.index(index, offsetBy: 2)
                        let byteString = String(string[index..<currentIndex])
                        guard let byte = UInt8(byteString, radix: 16) else {
                            throw Response.ResultModel.Error.unexpectedFormat("tx contains non-hex: \(byteString)")
                        }
                        data.append(byte)
                        index = currentIndex
                    }
                    guard data.count == 32 else {
                        throw Response.ResultModel.Error.unexpectedFormat("txid decoded \(data.count) bytes; expected 32")
                    }
                    return data
                }
            }
            
            public struct GetModel: JSONRPCResponse {
                public let blockHash: String
                public let blocktime: UInt
                public let confirmations: UInt
                public let hash: String
                public let hex: String
                public let locktime: UInt
                public let size: UInt
                public let time: UInt
                public let transactionID: String
                public let version: UInt
                public let inputs: [InputModel]
                public let outputs: [OutputModel]
                
                public struct InputModel: Decodable, Sendable {
                    public let scriptSig: ScriptSigModel
                    public let sequence: UInt
                    public let transactionID: String
                    public let indexNumberOfPreviousTransactionOutput: UInt
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.InputModel) {
                        self.scriptSig = ScriptSigModel(from: json.scriptSig)
                        self.sequence = json.sequence
                        self.transactionID = json.txid
                        self.indexNumberOfPreviousTransactionOutput = json.vout
                    }
                    
                    public struct ScriptSigModel: Decodable, Sendable {
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        
                        init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.InputModel.ScriptSigModel) {
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                        }
                    }
                }
                
                public struct OutputModel: Decodable, Sendable {
                    public let index: UInt
                    public let scriptPubKey: ScriptPubKeyModel
                    public let value: Double
                    
                    init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.OutputModel) {
                        self.index = json.n
                        self.scriptPubKey = ScriptPubKeyModel(from: json.scriptPubKey)
                        self.value = json.value
                    }
                    
                    public struct ScriptPubKeyModel: Decodable, Sendable {
                        public let addresses: [String]
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        public let requiredSignatures: UInt
                        public let type: String
                        
                        init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.OutputModel.ScriptPubKeyModel) {
                            self.addresses = json.addresses ?? .init()
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                            self.requiredSignatures = json.reqSigs ?? 0
                            self.type = json.type
                        }
                    }
                }
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .raw(let raw):
                        throw Error.unexpectedFormat("Expected detailed transaction information; received raw hex string: \(raw)")
                    case .detailed(let detailed):
                        guard let blockHash = detailed.blockhash else { throw Error.missingField("blockhash") }
                        guard let blocktime = detailed.blocktime else { throw Error.missingField("blocktime") }
                        guard let confirmations = detailed.confirmations else { throw Error.missingField("confirmations") }
                        guard let time = detailed.time else { throw Error.missingField("time") }
                        
                        self.blockHash = blockHash
                        self.blocktime = blocktime
                        self.confirmations = confirmations
                        self.hash = detailed.hash
                        self.hex = detailed.hex
                        self.locktime = detailed.locktime
                        self.size = detailed.size
                        self.time = time
                        self.transactionID = detailed.txid
                        self.version = detailed.version
                        self.inputs = detailed.vin.map { InputModel(from: $0) }
                        self.outputs = detailed.vout.map { OutputModel(from: $0) }
                    }
                }
            }
            
            public struct GetConfirmedBlockHashModel: JSONRPCResponse {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetConfirmedBlockHashModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            
            public struct GetHeightModel: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetHeightModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc
                }
            }
            
            public struct GetMerkleModel: JSONRPCResponse {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetMerkleModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            
            public struct IDFromPosModel: JSONRPCResponse {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.IDFromPosModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let height: UInt
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw Error.unexpectedFormat("Expected a height uint; got transaction hash and height array for TransactionModel.SubscribeModel: \(pairs.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .transactionHashAndHeight(let pairs):
                        var hashValue: String?
                        var heightValue: UInt?
                        
                        for pair in pairs {
                            switch pair {
                            case .transactionHash(let transactionHash):
                                guard hashValue == nil else { throw Error.unexpectedFormat("Duplicate transaction hash in notification payload") }
                                hashValue = transactionHash
                            case .height(let height):
                                guard heightValue == nil else { throw Error.unexpectedFormat("Duplicate height in notification payload") }
                                heightValue = height
                            }
                        }
                        
                        guard let transactionHash = hashValue else { throw Error.missingField("transactionHash") }
                        guard let height = heightValue else { throw Error.missingField("height") }
                        
                        self.subscriptionIdentifier = transactionHash
                        self.transactionHash = transactionHash
                        self.height = height
                    case .height(let height):
                        throw Error.unexpectedFormat("Expected [txid, height] for TransactionModel.SubscribeModel; got height only: \(height.description)")
                    }
                }
            }
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
            
            public struct DSProofModel {
                public struct GetModel: JSONRPCResponse {
                    public let dsProofID: String
                    public let transactionID: String
                    public let hex: String
                    public let outpoint: OutpointModel
                    public let descendants: [String]
                    
                    public struct OutpointModel: Decodable, Sendable {
                        public let transactionID: String
                        public let outputIndex: UInt
                        
                        init(from json: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel.OutpointModel) {
                            self.transactionID = json.txid
                            self.outputIndex = json.vout
                        }
                    }
                    
                    public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel
                    public init(fromRPC jsonrpc: JSONRPCModel) {
                        self.dsProofID = jsonrpc.dspid
                        self.transactionID = jsonrpc.txid
                        self.hex = jsonrpc.hex
                        self.outpoint = OutpointModel(from: jsonrpc.outpoint)
                        self.descendants = jsonrpc.descendants
                    }
                }
                
                public struct ListModel: JSONRPCResponse {
                    public let transactionHashes: [String]
                    
                    public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.ListModel
                    public init(fromRPC jsonrpc: JSONRPCModel) {
                        self.transactionHashes = jsonrpc
                    }
                }
                
                public struct SubscribeModel: JSONRPCResponse {
                    public let proof: GetModel?
                    
                    public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel
                    public init(fromRPC jsonrpc: JSONRPCModel) throws {
                        switch jsonrpc {
                        case .dsProof(let proof):
                            self.proof = proof.map { GetModel(fromRPC: $0) }
                        case .transactionHashAndDSProof(let pairs):
                            throw Error.unexpectedFormat("Expected DSProofModel or nil for DSProofModel.SubscribeModel initial response; got [txHash, DSProofModel]: \(pairs)")
                        }
                    }
                }
                
                public struct SubscribeNotificationModel: JSONRPCResponse {
                    public let subscriptionIdentifier: String
                    public let transactionHash: String
                    public let proof: GetModel?
                    
                    public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel
                    public init(fromRPC jsonrpc: JSONRPCModel) throws {
                        switch jsonrpc {
                        case .transactionHashAndDSProof(let pairs):
                            var hashValue: String?
                            var rawProofValue: Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel?
                            
                            for pair in pairs {
                                switch pair {
                                case .transactionHash(let hash):
                                    guard hashValue == nil else { throw Error.unexpectedFormat("Duplicate txHash in DSProofModel notification payload") }
                                    hashValue = hash
                                case .dsProof(let proof):
                                    guard rawProofValue == nil else { throw Error.unexpectedFormat("Duplicate dsProof in DSProofModel notification payload") }
                                    rawProofValue = proof
                                }
                            }
                            
                            guard let hash = hashValue else { throw Error.missingField("transactionHash") }
                            
                            self.subscriptionIdentifier = hash
                            self.transactionHash = hash
                            self.proof = rawProofValue.map { GetModel(fromRPC: $0) }
                        case .dsProof(let proof):
                            guard let rawProof = proof else { throw Error.unexpectedFormat("Nil DSProofModel in notification without accompanying transaction hash") }
                            let hash = rawProof.txid
                            self.subscriptionIdentifier = hash
                            self.transactionHash = hash
                            self.proof = GetModel(fromRPC: rawProof)
                        }
                    }
                }
                
                public struct UnsubscribeModel: JSONRPCResponse {
                    public let isSuccess: Bool
                    
                    public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.UnsubscribeModel
                    public init(fromRPC jsonrpc: JSONRPCModel) {
                        self.isSuccess = jsonrpc
                    }
                }
            }
        }
        
        public struct UTXOModel {
            public struct GetInfoModel: JSONRPCResponse {
                public let confirmedHeight: UInt?
                public let scriptHash: String
                public let value: UInt
                public let tokenData: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                
                public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.BlockchainModel.UTXOModel.GetInfoModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.confirmedHeight = jsonrpc.confirmed_height
                    self.scriptHash = jsonrpc.scripthash
                    self.value = jsonrpc.value
                    self.tokenData = jsonrpc.token_data
                }
            }
        }
    }
    
    public struct MempoolModel {
        public struct GetInfoModel: JSONRPCResponse {
            public let mempoolMinimumFee: Double?
            public let minimumRelayTransactionFee: Double?
            public let incrementalRelayFee: Double?
            public let unbroadcastCount: Int?
            public let isFullReplaceByFeeEnabled: Bool?
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.MempoolModel.GetInfoModel
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.mempoolMinimumFee = jsonrpc.mempoolminfee?.value
                self.minimumRelayTransactionFee = jsonrpc.minrelaytxfee?.value
                self.incrementalRelayFee = jsonrpc.incrementalrelayfee?.value
                self.unbroadcastCount = jsonrpc.unbroadcastcount
                self.isFullReplaceByFeeEnabled = jsonrpc.fullrbf
            }
        }
        
        public struct GetFeeHistogramModel: JSONRPCResponse {
            public let histogram: [ResultModel]
            
            public struct ResultModel: Decodable, Sendable {
                public let fee: Double
                public let virtualSize: UInt
                
                init(from pair: Response.JSONRPCModel.ResultModel.MempoolModel.FeeHistogram) throws {
                    guard pair.count == 2 else { throw Error.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)") }
                    let feeValue = pair[0].value
                    let virtualSizeValue = pair[1].value
                    guard feeValue.isFinite, feeValue >= 0 else { throw Error.unexpectedFormat("Invalid fee: \(feeValue)") }
                    guard virtualSizeValue.isFinite, virtualSizeValue >= 0, virtualSizeValue <= Double(UInt.max) else { throw Error.unexpectedFormat("Invalid vsize: \(virtualSizeValue)") }
                    
                    self.fee = feeValue
                    self.virtualSize = UInt(virtualSizeValue.rounded(.towardZero))
                }
            }
            
            public typealias JSONRPCModel = Response.JSONRPCModel.ResultModel.MempoolModel.GetFeeHistogramModel
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                self.histogram = try jsonrpc.enumerated().map { index, pair in
                    do { return try ResultModel(from: pair) }
                    catch { throw Error.unexpectedFormat("Malformed entry at index \(index): \(error)") }
                }.sorted { $0.fee < $1.fee }
            }
        }
    }
}
