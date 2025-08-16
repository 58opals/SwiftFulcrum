// Response+JSONRPC+Result.swift

import Foundation

extension Response.JSONRPC {
    public struct Result {
        public struct Blockchain {
            public typealias EstimateFee = Double
            
            public typealias RelayFee = Double
            
            public struct Address {
                public struct GetBalance: Decodable, Sendable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUse: Decodable, Sendable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistory = [GetHistoryItem]
                public struct GetHistoryItem: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempool = [GetMempoolItem]
                public struct GetMempoolItem: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetScriptHash = String
                
                public typealias ListUnspent = [ListUnspentItem]
                public struct ListUnspentItem: Decodable, Sendable {
                    public let height: UInt
                    public let token_data: Method.Blockchain.CashTokens.JSON?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable, Sendable {
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
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            
            public struct Block {
                public typealias Header = HeaderParameters
                public enum HeaderParameters: Decodable, Sendable {
                    case raw(String)
                    case proof(Proof)
                    
                    public struct Proof: Decodable, Sendable {
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
                        
                        if let multipleValues = try? container.decode(Proof.self) {
                            self = .proof(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(HeaderParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or Proof dictionary"))
                    }
                }
                
                public struct Headers: Decodable, Sendable {
                    public let count: UInt
                    public let hex: String
                    public let max: UInt
                }
            }
            
            public struct Header {
                public struct Get: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
            }
            
            public struct Headers {
                public struct GetTip: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable, Sendable {
                    case topHeader(GetTip)
                    case newHeader([GetTip])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(GetTip.self) {
                            self = .topHeader(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([GetTip].self) {
                            self = .newHeader(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected top header's height and hex or new header's heights and hexes"))
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            
            public struct Transaction {
                public typealias Broadcast = Data
                
                public typealias Get = GetParameters
                public enum GetParameters: Decodable, Sendable {
                    case raw(String)
                    case detailed(Detailed)
                    
                    public struct Detailed: Decodable, Sendable {
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
                        public let vin: [Input]
                        public let vout: [Output]
                        
                        public struct Input: Decodable, Sendable {
                            public let scriptSig: ScriptSig
                            public let sequence: UInt
                            public let txid: String
                            public let vout: UInt
                            
                            public struct ScriptSig: Decodable, Sendable {
                                public let asm: String
                                public let hex: String
                            }
                        }
                        
                        public struct Output: Decodable, Sendable {
                            public let n: UInt
                            public let scriptPubKey: ScriptPubKey
                            public let value: Double
                            
                            public struct ScriptPubKey: Decodable, Sendable {
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
                        
                        if let multipleValues = try? container.decode(Detailed.self) {
                            self = .detailed(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(GetParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or Detailed"))
                    }
                }
                
                public struct GetConfirmedBlockHash: Decodable, Sendable {
                    public let block_hash: String
                    public let block_header: String?
                    public let block_height: UInt
                }
                
                public typealias GetHeight = UInt
                
                public struct GetMerkle: Decodable, Sendable {
                    public let merkle: [String]
                    public let block_height: UInt
                    public let pos: UInt
                }
                
                public struct IDFromPos: Decodable, Sendable {
                    public let merkle: [String]
                    public let tx_hash: String
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable, Sendable {
                    case height(UInt)
                    case transactionHashAndHeight([TransactionHashAndHeight])
                    
                    public enum TransactionHashAndHeight: Decodable, Sendable {
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
                            
                            throw DecodingError.typeMismatch(TransactionHashAndHeight.self,
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
                        
                        if let stringAndUIntResult = try? container.decode([TransactionHashAndHeight].self) {
                            self = .transactionHashAndHeight(stringAndUIntResult)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected UInt (height) or String and UInt (transaction hash and height)"))
                    }
                }
                
                public typealias Unsubscribe = Bool
                
                public struct DSProof {
                    public struct Get: Decodable, Sendable {
                        public let dspid: String
                        public let txid: String
                        public let hex: String
                        public let outpoint: Outpoint
                        public let descendants: [String]
                        
                        public struct Outpoint: Decodable, Sendable {
                            public let txid: String
                            public let vout: UInt
                        }
                    }
                    
                    public typealias List = [String]
                    
                    public typealias Subscribe = SubscribeParameters
                    public enum SubscribeParameters: Decodable, Sendable {
                        case dsProof(Get?)
                        case transactionHashAndDSProof([TransactionHashAndDSProof])
                        
                        public enum TransactionHashAndDSProof: Decodable, Sendable {
                            case transactionHash(String)
                            case dsProof(Get)
                            
                            public init(from decoder: Decoder) throws {
                                let container = try decoder.singleValueContainer()
                                
                                if let stringResult = try? container.decode(String.self) {
                                    self = .transactionHash(stringResult)
                                    return
                                }
                                
                                if let getResult = try? container.decode(Get.self) {
                                    self = .dsProof(getResult)
                                    return
                                }
                                
                                throw DecodingError.typeMismatch(TransactionHashAndDSProof.self,
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
                            
                            if let getResult = try? container.decode(Get?.self) {
                                self = .dsProof(getResult)
                                return
                            }
                            
                            if let stringAndUGetResult = try? container.decode([TransactionHashAndDSProof].self) {
                                self = .transactionHashAndDSProof(stringAndUGetResult)
                                return
                            }
                            
                            throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                             .init(codingPath: decoder.codingPath,
                                                                   debugDescription: "Expected nil, a DSProof, or [txHash, dsProof]"))
                        }
                    }
                    
                    public typealias Unsubscribe = Bool
                }
            }
            
            public struct UTXO {
                public struct GetInfo: Decodable, Sendable {
                    public let confirmed_height: UInt?
                    public let scripthash: String
                    public let value: UInt
                    public let token_data: Method.Blockchain.CashTokens.JSON?
                }
            }
        }
        
        public struct Mempool {
            public typealias FeeHistogram = [UInt]
            public typealias GetFeeHistogram = [FeeHistogram]
        }
    }
}
