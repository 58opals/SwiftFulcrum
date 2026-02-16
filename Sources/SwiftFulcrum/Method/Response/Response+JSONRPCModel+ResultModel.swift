// Response+JSONRPCModel+ResultModel.swift

import Foundation

extension Response.JSONRPCModel {
    public struct ResultModel {
        public struct ServerModel {
            public struct PingModel: Decodable, Sendable {}
            
            public struct VersionModel: Decodable, Sendable {
                public let serverVersion: String
                public let protocolVersion: String
                
                public init(from decoder: Decoder) throws {
                    var container = try decoder.unkeyedContainer()
                    guard !container.isAtEnd else {
                        throw DecodingError.dataCorruptedError(in: container,
                                                               debugDescription: "Expected server and protocol version pair")
                    }
                    
                    self.serverVersion = try container.decode(String.self)
                    guard !container.isAtEnd else {
                        throw DecodingError.dataCorruptedError(in: container,
                                                               debugDescription: "Missing negotiated protocol version")
                    }
                    self.protocolVersion = try container.decode(String.self)
                }
            }
            
            public struct FeaturesModel: Decodable, Sendable {
                public let genesis_hash: String
                public let hash_function: String
                public let server_version: String
                public let protocol_max: String
                public let protocol_min: String
                public let pruning: Int?
                public let hosts: [String: HostModel]?
                public let dsproof: Bool?
                public let cashtokens: Bool?
                public let rpa: ReusablePaymentAddressModel?
                public let broadcast_package: Bool?
                
                public struct HostModel: Decodable, Sendable {
                    public let ssl_port: Int?
                    public let tcp_port: Int?
                    public let ws_port: Int?
                    public let wss_port: Int?
                }
                
                public struct ReusablePaymentAddressModel: Decodable, Sendable {
                    public let history_block_limit: Int?
                    public let max_history: Int?
                    public let prefix_bits: Int?
                    public let prefix_bits_min: Int?
                    public let starting_height: Int?
                }
            }
        }
        
        public struct BlockchainModel {
            public typealias EstimateFeeModel = Double
            
            public typealias RelayFeeModel = Double
            
            public struct ScriptHashModel {
                public struct GetBalanceModel: Decodable, Sendable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUseModel: Decodable, Sendable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistoryModel = [GetHistoryItemModel]
                public struct GetHistoryItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempoolModel = [GetMempoolItemModel]
                public struct GetMempoolItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias ListUnspentModel = [ListUnspentItemModel]
                public struct ListUnspentItemModel: Decodable, Sendable {
                    public let height: UInt
                    public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case status(String)
                    case scripthashAndStatus([String?])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .status(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([String?].self) {
                            self = .scripthashAndStatus(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
            }
            
            public struct AddressModel {
                public struct GetBalanceModel: Decodable, Sendable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUseModel: Decodable, Sendable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistoryModel = [GetHistoryItemModel]
                public struct GetHistoryItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempoolModel = [GetMempoolItemModel]
                public struct GetMempoolItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetScriptHashModel = String
                
                public typealias ListUnspentModel = [ListUnspentItemModel]
                public struct ListUnspentItemModel: Decodable, Sendable {
                    public let height: UInt
                    public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case status(String)
                    case addressAndStatus([String?])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .status(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([String?].self) {
                            self = .addressAndStatus(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
            }
            
            public struct BlockModel {
                public typealias HeaderModel = HeaderParametersModel
                public enum HeaderParametersModel: Decodable, Sendable {
                    case raw(String)
                    case proof(ProofModel)
                    
                    public struct ProofModel: Decodable, Sendable {
                        public let branch: [String]
                        public let header: String
                        public let root: String
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .raw(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode(ProofModel.self) {
                            self = .proof(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(HeaderParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or ProofModel dictionary"))
                    }
                }
                
                public struct HeadersModel: Decodable, Sendable {
                    public let count: UInt
                    public let hex: String
                    public let max: UInt
                    public let root: String?
                    public let branch: [String]?
                    public let headers: [String]?
                    
                    private enum CodingKeysModel: String, CodingKey {
                        case count
                        case hex
                        case headers
                        case max
                        case root
                        case branch
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeysModel.self)
                        
                        self.count = try container.decode(UInt.self, forKey: .count)
                        self.max = try container.decode(UInt.self, forKey: .max)
                        self.headers = try container.decodeIfPresent([String].self, forKey: .headers)
                        
                        if let headerList = headers {
                            self.hex = headerList.joined()
                        } else if let legacyHex = try container.decodeIfPresent(String.self, forKey: .hex) {
                            self.hex = legacyHex
                        } else {
                            throw DecodingError.valueNotFound(String.self,
                                                              .init(codingPath: decoder.codingPath,
                                                                    debugDescription: "Expected either hex or headers fields"))
                        }
                        
                        self.root = try container.decodeIfPresent(String.self, forKey: .root)
                        self.branch = try container.decodeIfPresent([String].self, forKey: .branch)
                    }
                }
            }
            
            public struct HeaderModel {
                public struct GetModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
            }
            
            public struct HeadersModel {
                public struct GetTipModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case topHeader(GetTipModel)
                    case newHeader([GetTipModel])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(GetTipModel.self) {
                            self = .topHeader(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([GetTipModel].self) {
                            self = .newHeader(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected top header's height and hex or new header's heights and hexes"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
            }
            
            public struct TransactionModel {
                public typealias BroadcastModel = String
                
                public typealias GetModel = GetParametersModel
                public enum GetParametersModel: Decodable, Sendable {
                    case raw(String)
                    case detailed(DetailedModel)
                    
                    public struct DetailedModel: Decodable, Sendable {
                        public let blockhash: String?
                        public let blocktime: UInt?
                        public let confirmations: UInt?
                        public let hash: String
                        public let hex: String
                        public let locktime: UInt
                        public let size: UInt
                        public let time: UInt?
                        public let txid: String
                        public let version: UInt
                        public let vin: [InputModel]
                        public let vout: [OutputModel]
                        
                        public struct InputModel: Decodable, Sendable {
                            public let scriptSig: ScriptSigModel
                            public let sequence: UInt
                            public let txid: String
                            public let vout: UInt
                            
                            public struct ScriptSigModel: Decodable, Sendable {
                                public let asm: String
                                public let hex: String
                            }
                        }
                        
                        public struct OutputModel: Decodable, Sendable {
                            public let n: UInt
                            public let scriptPubKey: ScriptPubKeyModel
                            public let value: Double
                            
                            public struct ScriptPubKeyModel: Decodable, Sendable {
                                public let addresses: [String]?
                                public let asm: String
                                public let hex: String
                                public let reqSigs: UInt?
                                public let type: String
                            }
                        }
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .raw(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode(DetailedModel.self) {
                            self = .detailed(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(GetParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or DetailedModel"))
                    }
                }
                
                public struct GetConfirmedBlockHashModel: Decodable, Sendable {
                    public let block_hash: String
                    public let block_header: String?
                    public let block_height: UInt
                }
                
                public typealias GetHeightModel = UInt
                
                public struct GetMerkleModel: Decodable, Sendable {
                    public let merkle: [String]
                    public let block_height: UInt
                    public let pos: UInt
                }
                
                public struct IDFromPosModel: Decodable, Sendable {
                    public let merkle: [String]
                    public let tx_hash: String
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case height(UInt)
                    case transactionHashAndHeight([TransactionHashAndHeightModel])
                    
                    public enum TransactionHashAndHeightModel: Decodable, Sendable {
                        case transactionHash(String)
                        case height(UInt)
                        
                        public init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            
                            if let stringResult = try? container.decode(String.self) {
                                self = .transactionHash(stringResult)
                                return
                            }
                            
                            if let uintResult = try? container.decode(UInt.self) {
                                self = .height(uintResult)
                                return
                            }
                            
                            throw DecodingError.typeMismatch(TransactionHashAndHeightModel.self,
                                                             .init(codingPath: decoder.codingPath,
                                                                   debugDescription: "Expected UInt or String"))
                        }
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let uintResult = try? container.decode(UInt.self) {
                            self = .height(uintResult)
                            return
                        }
                        
                        if let stringAndUIntResult = try? container.decode([TransactionHashAndHeightModel].self) {
                            self = .transactionHashAndHeight(stringAndUIntResult)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected UInt (height) or String and UInt (transaction hash and height)"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
                
                public struct DSProofModel {
                    public struct GetModel: Decodable, Sendable {
                        public let dspid: String
                        public let txid: String
                        public let hex: String
                        public let outpoint: OutpointModel
                        public let descendants: [String]
                        
                        public struct OutpointModel: Decodable, Sendable {
                            public let txid: String
                            public let vout: UInt
                        }
                    }
                    
                    public typealias ListModel = [String]
                    
                    public typealias SubscribeModel = SubscribeParametersModel
                    public enum SubscribeParametersModel: Decodable, Sendable {
                        case dsProof(GetModel?)
                        case transactionHashAndDSProof([TransactionHashAndDSProofModel])
                        
                        public enum TransactionHashAndDSProofModel: Decodable, Sendable {
                            case transactionHash(String)
                            case dsProof(GetModel)
                            
                            public init(from decoder: Decoder) throws {
                                let container = try decoder.singleValueContainer()
                                
                                if let stringResult = try? container.decode(String.self) {
                                    self = .transactionHash(stringResult)
                                    return
                                }
                                
                                if let getResult = try? container.decode(GetModel.self) {
                                    self = .dsProof(getResult)
                                    return
                                }
                                
                                throw DecodingError.typeMismatch(TransactionHashAndDSProofModel.self,
                                                                 .init(codingPath: decoder.codingPath,
                                                                       debugDescription: "Expected transaction hash or double-spending proof"))
                            }
                        }
                        
                        public init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            
                            if container.decodeNil() {
                                self = .dsProof(nil)
                                return
                            }
                            
                            if let getResult = try? container.decode(GetModel?.self) {
                                self = .dsProof(getResult)
                                return
                            }
                            
                            if let stringAndUGetResult = try? container.decode([TransactionHashAndDSProofModel].self) {
                                self = .transactionHashAndDSProof(stringAndUGetResult)
                                return
                            }
                            
                            throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                             .init(codingPath: decoder.codingPath,
                                                                   debugDescription: "Expected nil, a DSProofModel, or [txHash, dsProof]"))
                        }
                    }
                    
                    public typealias UnsubscribeModel = Bool
                }
            }
            
            public struct UTXOModel {
                public struct GetInfoModel: Decodable, Sendable {
                    public let confirmed_height: UInt?
                    public let scripthash: String
                    public let value: UInt
                    public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                }
            }
        }
        
        public struct MempoolModel {
            public struct FlexibleNumberModel: Decodable,Sendable {
                public let value: Double
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    if let double = try? container.decode(Double.self) { self.value = double; return }
                    if let int = try? container.decode(Int.self) { self.value = Double(int); return }
                    if let uint = try? container.decode(UInt.self) { self.value = Double(uint); return }
                    if let string = try? container.decode(String.self), let double = Double(string) { self.value = double; return }
                    
                    throw DecodingError.typeMismatch(Double.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected number or numeric string"))
                }
            }
            
            public struct GetInfoModel: Decodable, Sendable {
                public let mempoolminfee: FlexibleNumberModel?
                public let minrelaytxfee: FlexibleNumberModel?
                public let incrementalrelayfee: FlexibleNumberModel?
                public let unbroadcastcount: Int?
                public let fullrbf: Bool?
            }
            
            public typealias FeeHistogram = [FlexibleNumberModel]
            public typealias GetFeeHistogramModel = [FeeHistogram]
        }
    }
}
