// Response+Result.swift

import Foundation

extension Response { public struct Result {} }

public protocol JSONRPCConvertible: Decodable, Sendable {
    associatedtype JSONRPC: Decodable
    init(fromRPC jsonrpc: JSONRPC) throws
}

public protocol JSONRPCNilAcceptingConvertible: JSONRPCConvertible {
    init(nilValue: ())
}

extension Response.Result {
    public struct Server {
        public struct Ping: JSONRPCConvertible {
            public typealias JSONRPC = Response.JSONRPC.Result.Server.Ping?
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard jsonrpc == nil else {
                    throw Response.Result.Error.unexpectedFormat("Expected null result for server.ping().")
                }
            }
        }
        
        public struct Version: JSONRPCConvertible {
            public let serverVersion: String
            public let negotiatedProtocolVersion: ProtocolVersion
            
            public typealias JSONRPC = Response.JSONRPC.Result.Server.Version
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard let protocolVersion = ProtocolVersion(string: jsonrpc.protocolVersion) else {
                    throw Error.unexpectedFormat("Negotiated protocol version is invalid: \(jsonrpc.protocolVersion)")
                }
                
                self.serverVersion = jsonrpc.serverVersion
                self.negotiatedProtocolVersion = protocolVersion
            }
        }
        
        public struct Features: JSONRPCConvertible {
            public let genesisHash: String
            public let hashFunction: String
            public let serverVersion: String
            public let minimumProtocolVersion: ProtocolVersion
            public let maximumProtocolVersion: ProtocolVersion
            public let pruningLimit: Int?
            public let hosts: [String: Host]?
            public let hasDoubleSpendProofs: Bool?
            public let hasCashTokens: Bool?
            public let reusablePaymentAddress: ReusablePaymentAddress?
            public let hasBroadcastPackageSupport: Bool?
            
            public typealias JSONRPC = Response.JSONRPC.Result.Server.Features
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard let minVersion = ProtocolVersion(string: jsonrpc.protocol_min) else {
                    throw Error.unexpectedFormat("Minimum protocol version is invalid: \(jsonrpc.protocol_min)")
                }
                guard let maxVersion = ProtocolVersion(string: jsonrpc.protocol_max) else {
                    throw Error.unexpectedFormat("Maximum protocol version is invalid: \(jsonrpc.protocol_max)")
                }
                
                self.genesisHash = jsonrpc.genesis_hash
                self.hashFunction = jsonrpc.hash_function
                self.serverVersion = jsonrpc.server_version
                self.minimumProtocolVersion = minVersion
                self.maximumProtocolVersion = maxVersion
                self.pruningLimit = jsonrpc.pruning
                self.hosts = jsonrpc.hosts?.mapValues { Host(from: $0) }
                self.hasDoubleSpendProofs = jsonrpc.dsproof
                self.hasCashTokens = jsonrpc.cashtokens
                self.reusablePaymentAddress = jsonrpc.rpa.map(ReusablePaymentAddress.init(from:))
                self.hasBroadcastPackageSupport = jsonrpc.broadcast_package
            }
            
            public struct Host: Decodable, Sendable {
                public let sslPort: Int?
                public let tcpPort: Int?
                public let webSocketPort: Int?
                public let secureWebSocketPort: Int?
                
                init(from json: JSONRPC.Host) {
                    self.sslPort = json.ssl_port
                    self.tcpPort = json.tcp_port
                    self.webSocketPort = json.ws_port
                    self.secureWebSocketPort = json.wss_port
                }
            }
            
            public struct ReusablePaymentAddress: Decodable, Sendable {
                public let historyBlockLimit: Int?
                public let maximumHistoryItems: Int?
                public let indexedPrefixBits: Int?
                public let minimumPrefixBits: Int?
                public let startingHeight: Int?
                
                init(from json: JSONRPC.ReusablePaymentAddress) {
                    self.historyBlockLimit = json.history_block_limit
                    self.maximumHistoryItems = json.max_history
                    self.indexedPrefixBits = json.prefix_bits
                    self.minimumPrefixBits = json.prefix_bits_min
                    self.startingHeight = json.starting_height
                }
            }
        }
    }
    
    public struct Blockchain {
        public struct EstimateFee: JSONRPCConvertible {
            public let fee: Double
            
            public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.EstimateFee
            public init(fromRPC jsonrpc: JSONRPC) {
                self.fee = jsonrpc
            }
        }
        
        public struct RelayFee: JSONRPCConvertible {
            public let fee: Double
            
            public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.RelayFee
            public init(fromRPC jsonrpc: JSONRPC) {
                self.fee = jsonrpc
            }
        }
        
        public struct ScriptHash {
            public struct GetBalance: JSONRPCConvertible {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.GetBalance
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUse: JSONRPCConvertible {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var found: Bool { blockHash != nil }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.GetFirstUse?
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
            
            public struct GetHistory: JSONRPCConvertible {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistory
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetMempool: JSONRPCConvertible {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempool
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct ListUnspent: JSONRPCConvertible {
                public let items: [Item]
                
                public struct Item: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspent
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: JSONRPCConvertible {
                public let status: String?
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe?
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .scripthashAndStatus(let pair):
                        throw Error.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHash.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCConvertible {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
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
            
            public struct Unsubscribe: JSONRPCConvertible {
                public let success: Bool
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.ScriptHash.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.success = jsonrpc
                }
            }
        }
        
        public struct Address {
            public struct GetBalance: JSONRPCConvertible {
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.GetBalance
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.confirmed = jsonrpc.confirmed
                    self.unconfirmed = jsonrpc.unconfirmed
                }
            }
            
            public struct GetFirstUse: JSONRPCConvertible {
                public let blockHash: String?
                public let height: UInt?
                public let transactionHash: String?
                public var found: Bool { blockHash != nil }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.GetFirstUse?
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
            
            public struct GetHistory: JSONRPCConvertible {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.Address.GetHistoryItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.GetHistory
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetMempool: JSONRPCConvertible {
                public let transactions: [Transaction]
                public struct Transaction: Decodable, Sendable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.Address.GetMempoolItem) {
                        self.height = json.height
                        self.transactionHash = json.tx_hash
                        self.fee = json.fee
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.GetMempool
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.transactions = jsonrpc.map { Transaction(from: $0) }
                }
            }
            
            public struct GetScriptHash: JSONRPCConvertible {
                public let scriptHash: String
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.GetScriptHash
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.scriptHash = jsonrpc
                }
            }
            
            public struct ListUnspent: JSONRPCConvertible {
                public let items: [Item]
                
                public struct Item: Decodable, Sendable {
                    public let height: UInt
                    public let tokenData: Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.Address.ListUnspentItem) {
                        self.height = json.height
                        self.tokenData = json.token_data
                        self.transactionHash = json.tx_hash
                        self.transactionPosition = json.tx_pos
                        self.value = json.value
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.ListUnspent
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.items = jsonrpc.map { Item(from: $0) }
                }
            }
            
            public struct Subscribe: JSONRPCConvertible {
                public let status: String?
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.Subscribe?
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    guard let jsonrpc else {
                        self.status = nil
                        return
                    }
                    switch jsonrpc {
                    case .status(let statusString):
                        self.status = statusString
                    case .addressAndStatus(let pair):
                        throw Error.unexpectedFormat("Expected a status string; got address and status array for Address.Subscribe: \(pair.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCConvertible {
                public let subscriptionIdentifier: String
                public let status: String?
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
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
            
            public struct Unsubscribe: JSONRPCConvertible {
                public let success: Bool
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Address.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.success = jsonrpc
                }
            }
        }
        
        public struct Block {
            public struct Header: JSONRPCConvertible {
                public let hex: String
                public let proof: Proof?
                
                public struct Proof: Decodable, Sendable {
                    public let branch: [String]
                    public let root: String
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Block.Header
                public init(fromRPC jsonrpc: JSONRPC) {
                    switch jsonrpc {
                    case .raw(let raw):
                        self.hex = raw
                        self.proof = nil
                    case .proof(let proof):
                        self.hex = proof.header
                        self.proof = Proof(branch: proof.branch,
                                           root: proof.root)
                    }
                }
            }
            
            public struct Headers: JSONRPCConvertible {
                public let count: UInt
                public let hex: String
                public let max: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Block.Headers
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.count = jsonrpc.count
                    self.hex = jsonrpc.hex
                    self.max = jsonrpc.max
                }
            }
        }
        
        public struct Header {
            public struct Get: JSONRPCConvertible {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Header.Get
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        
        public struct Headers {
            public struct GetTip: JSONRPCConvertible {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Headers.GetTip
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
            
            public struct Subscribe: JSONRPCConvertible {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .topHeader(let tip):
                        self.height = tip.height
                        self.hex = tip.hex
                    case .newHeader(let batch) where batch.count == 1:
                        self.height = batch[0].height
                        self.hex = batch[0].hex
                    case .newHeader(let batch):
                        throw Response.Result.Error.unexpectedFormat("Expected single top header; received batch of new headers: \(batch.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCConvertible {
                public let subscriptionIdentifier: String
                public let blocks: [Block]
                
                public struct Block: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Headers.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    self.subscriptionIdentifier = Method.blockchain(.headers(.subscribe)).path
                    
                    switch jsonrpc {
                    case .newHeader(let list):
                        guard !list.isEmpty else { throw Error.missingField("header list empty") }
                        self.blocks = list.map { Block(height: $0.height, hex: $0.hex) }
                    case .topHeader(let tip):
                        self.blocks = [Block(height: tip.height, hex: tip.hex)]
                    }
                }
            }
            
            public struct Unsubscribe: JSONRPCConvertible {
                public let success: Bool
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Headers.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.success = jsonrpc
                }
            }
        }
        
        public struct Transaction {
            public struct Broadcast: JSONRPCConvertible {
                public let transactionHash: Data
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.Broadcast
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    self.transactionHash = try Self.decodeHex(jsonrpc)
                }
                
                private static func decodeHex(_ hex: String) throws -> Data {
                    let string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard string.count % 2 == 0 else {
                        throw Response.Result.Error.unexpectedFormat("txid has odd hex length: \(string.count)")
                    }
                    var data = Data(); data.reserveCapacity(string.count / 2)
                    var index = string.startIndex
                    while index < string.endIndex {
                        let currentIndex = string.index(index, offsetBy: 2)
                        let byteString = String(string[index..<currentIndex])
                        guard let byte = UInt8(byteString, radix: 16) else {
                            throw Response.Result.Error.unexpectedFormat("tx contains non-hex: \(byteString)")
                        }
                        data.append(byte)
                        index = currentIndex
                    }
                    guard data.count == 32 else {
                        throw Response.Result.Error.unexpectedFormat("txid decoded \(data.count) bytes; expected 32")
                    }
                    return data
                }
            }
            
            public struct Get: JSONRPCConvertible {
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
                public let inputs: [Input]
                public let outputs: [Output]
                
                public struct Input: Decodable, Sendable {
                    public let scriptSig: ScriptSig
                    public let sequence: UInt
                    public let transactionID: String
                    public let indexNumberOfPreviousTransactionOutput: UInt
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input) {
                        self.scriptSig = ScriptSig(from: json.scriptSig)
                        self.sequence = json.sequence
                        self.transactionID = json.txid
                        self.indexNumberOfPreviousTransactionOutput = json.vout
                    }
                    
                    public struct ScriptSig: Decodable, Sendable {
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        
                        init(from json: Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input.ScriptSig) {
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                        }
                    }
                }
                
                public struct Output: Decodable, Sendable {
                    public let index: UInt
                    public let scriptPubKey: ScriptPubKey
                    public let value: Double
                    
                    init(from json: Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output) {
                        self.index = json.n
                        self.scriptPubKey = ScriptPubKey(from: json.scriptPubKey)
                        self.value = json.value
                    }
                    
                    public struct ScriptPubKey: Decodable, Sendable {
                        public let addresses: [String]
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        public let requiredSignatures: UInt
                        public let type: String
                        
                        init(from json: Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output.ScriptPubKey) {
                            self.addresses = json.addresses ?? .init()
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                            self.requiredSignatures = json.reqSigs ?? 0
                            self.type = json.type
                        }
                    }
                }
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.Get
                public init(fromRPC jsonrpc: JSONRPC) throws {
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
                        self.inputs = detailed.vin.map { Input(from: $0) }
                        self.outputs = detailed.vout.map { Output(from: $0) }
                    }
                }
            }
            
            public struct GetConfirmedBlockHash: JSONRPCConvertible {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.blockHash = jsonrpc.block_hash
                    self.blockHeader = jsonrpc.block_header
                    self.blockHeight = jsonrpc.block_height
                }
            }
            
            public struct GetHeight: JSONRPCConvertible {
                public let height: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.GetHeight
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.height = jsonrpc
                }
            }
            
            public struct GetMerkle: JSONRPCConvertible {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.merkle = jsonrpc.merkle
                    self.blockHeight = jsonrpc.block_height
                    self.position = jsonrpc.pos
                }
            }
            
            public struct IDFromPos: JSONRPCConvertible {
                public let merkle: [String]
                public let transactionHash: String
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.merkle = jsonrpc.merkle
                    self.transactionHash = jsonrpc.tx_hash
                }
            }
            
            public struct Subscribe: JSONRPCConvertible {
                public let height: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .height(let height):
                        self.height = height
                    case .transactionHashAndHeight(let pairs):
                        throw Error.unexpectedFormat("Expected a height uint; got transaction hash and height array for Transaction.Subscribe: \(pairs.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: JSONRPCConvertible {
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPC) throws {
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
                        throw Error.unexpectedFormat("Expected [txid, height] for Transaction.Subscribe; got height only: \(height.description)")
                    }
                }
            }
            
            public struct Unsubscribe: JSONRPCConvertible {
                public let success: Bool
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.success = jsonrpc
                }
            }
            
            public struct DSProof {
                public struct Get: JSONRPCConvertible {
                    public let dsProofID: String
                    public let transactionID: String
                    public let hex: String
                    public let outpoint: Outpoint
                    public let descendants: [String]
                    
                    public struct Outpoint: Decodable, Sendable {
                        public let transactionID: String
                        public let outputIndex: UInt
                        
                        init(from json: Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.Outpoint) {
                            self.transactionID = json.txid
                            self.outputIndex = json.vout
                        }
                    }
                    
                    public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get
                    public init(fromRPC jsonrpc: JSONRPC) {
                        self.dsProofID = jsonrpc.dspid
                        self.transactionID = jsonrpc.txid
                        self.hex = jsonrpc.hex
                        self.outpoint = Outpoint(from: jsonrpc.outpoint)
                        self.descendants = jsonrpc.descendants
                    }
                }
                
                public struct List: JSONRPCConvertible {
                    public let transactionHashes: [String]
                    
                    public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.DSProof.List
                    public init(fromRPC jsonrpc: JSONRPC) {
                        self.transactionHashes = jsonrpc
                    }
                }
                
                public struct Subscribe: JSONRPCConvertible {
                    public let proof: Get?
                    
                    public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe
                    public init(fromRPC jsonrpc: JSONRPC) throws {
                        switch jsonrpc {
                        case .dsProof(let proof):
                            self.proof = proof.map { Get(fromRPC: $0) }
                        case .transactionHashAndDSProof(let pairs):
                            throw Error.unexpectedFormat("Expected DSProof or nil for DSProof.Subscribe initial response; got [txHash, DSProof]: \(pairs)")
                        }
                    }
                }
                
                public struct SubscribeNotification: JSONRPCConvertible {
                    public let subscriptionIdentifier: String
                    public let transactionHash: String
                    public let proof: Get?
                    
                    public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe
                    public init(fromRPC jsonrpc: JSONRPC) throws {
                        switch jsonrpc {
                        case .transactionHashAndDSProof(let pairs):
                            var hashValue: String?
                            var rawProofValue: Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get?
                            
                            for pair in pairs {
                                switch pair {
                                case .transactionHash(let hash):
                                    guard hashValue == nil else { throw Error.unexpectedFormat("Duplicate txHash in DSProof notification payload") }
                                    hashValue = hash
                                case .dsProof(let proof):
                                    guard rawProofValue == nil else { throw Error.unexpectedFormat("Duplicate dsProof in DSProof notification payload") }
                                    rawProofValue = proof
                                }
                            }
                            
                            guard let hash = hashValue else { throw Error.missingField("transactionHash") }
                            
                            self.subscriptionIdentifier = hash
                            self.transactionHash = hash
                            self.proof = rawProofValue.map { Get(fromRPC: $0) }
                        case .dsProof(let proof):
                            guard let rawProof = proof else { throw Error.unexpectedFormat("Nil DSProof in notification without accompanying transaction hash") }
                            let hash = rawProof.txid
                            self.subscriptionIdentifier = hash
                            self.transactionHash = hash
                            self.proof = Get(fromRPC: rawProof)
                        }
                    }
                }
                
                public struct Unsubscribe: JSONRPCConvertible {
                    public let success: Bool
                    
                    public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Unsubscribe
                    public init(fromRPC jsonrpc: JSONRPC) {
                        self.success = jsonrpc
                    }
                }
            }
        }
        
        public struct UTXO {
            public struct GetInfo: JSONRPCConvertible {
                public let confirmedHeight: UInt?
                public let scriptHash: String
                public let value: UInt
                public let tokenData: Method.Blockchain.CashTokens.JSON?
                
                public typealias JSONRPC = Response.JSONRPC.Result.Blockchain.UTXO.GetInfo
                public init(fromRPC jsonrpc: JSONRPC) {
                    self.confirmedHeight = jsonrpc.confirmed_height
                    self.scriptHash = jsonrpc.scripthash
                    self.value = jsonrpc.value
                    self.tokenData = jsonrpc.token_data
                }
            }
        }
    }
    
    public struct Mempool {
        public struct GetFeeHistogram: JSONRPCConvertible {
            public let histogram: [Result]
            
            public struct Result: Decodable, Sendable {
                public let fee: Double
                public let virtualSize: UInt
                
                init(from pair: Response.JSONRPC.Result.Mempool.FeeHistogram) throws {
                    guard pair.count == 2 else { throw Error.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)") }
                    let feeValue = pair[0].value
                    let virtualSizeValue = pair[1].value
                    guard feeValue.isFinite, feeValue >= 0 else { throw Error.unexpectedFormat("Invalid fee: \(feeValue)") }
                    guard virtualSizeValue.isFinite, virtualSizeValue >= 0, virtualSizeValue <= Double(UInt.max) else { throw Error.unexpectedFormat("Invalid vsize: \(virtualSizeValue)") }
                    
                    self.fee = feeValue
                    self.virtualSize = UInt(virtualSizeValue.rounded(.towardZero))
                }
            }
            
            public typealias JSONRPC = Response.JSONRPC.Result.Mempool.GetFeeHistogram
            public init(fromRPC jsonrpc: JSONRPC) throws {
                self.histogram = try jsonrpc.enumerated().map { index, pair in
                    do { return try Result(from: pair) }
                    catch { throw Error.unexpectedFormat("Malformed entry at index \(index): \(error)") }
                }.sorted { $0.fee < $1.fee }
            }
        }
    }
}
