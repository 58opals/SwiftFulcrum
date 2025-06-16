// Response+JSONRPC+Result.swift

import Foundation

extension Response.JSONRPC {
    public struct Result {
        public struct Blockchain {
            public typealias EstimateFee = Double
            
            public typealias RelayFee = Double
            
            public struct Address {
                public struct GetBalance: Decodable, Sendable {
                    let confirmed: UInt64
                    let unconfirmed: Int64
                }
                
                public struct GetFirstUse: Decodable, Sendable {
                    let block_hash: String
                    let height: UInt
                    let tx_hash: String
                }
                
                public typealias GetHistory = [GetHistoryItem]
                public struct GetHistoryItem: Decodable, Sendable {
                    let height: Int
                    let tx_hash: String
                    let fee: UInt?
                }
                
                public typealias GetMempool = [GetMempoolItem]
                public struct GetMempoolItem: Decodable, Sendable {
                    let height: Int
                    let tx_hash: String
                    let fee: UInt?
                }
                
                public typealias GetScriptHash = String
                
                public typealias ListUnspent = [ListUnspentItem]
                public struct ListUnspentItem: Decodable, Sendable {
                    let height: UInt
                    let token_data: Method.Blockchain.CashTokens.JSON?
                    let tx_hash: String
                    let tx_pos: UInt
                    let value: UInt64
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
                        let branch: [String]
                        let header: String
                        let root: String
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
                    let count: UInt
                    let hex: String
                    let max: UInt
                }
            }
            
            public struct Header {
                public struct Get: Decodable, Sendable {
                    let height: UInt
                    let hex: String
                }
            }
            
            public struct Headers {
                public struct GetTip: Decodable, Sendable {
                    let height: UInt
                    let hex: String
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
                        let blockhash: String?
                        let blocktime: UInt?
                        let confirmations: UInt?
                        let hash: String
                        let hex: String
                        let locktime: UInt
                        let size: UInt
                        let time: UInt?
                        let txid: String
                        let version: UInt
                        let vin: [Input]
                        let vout: [Output]
                        
                        public struct Input: Decodable, Sendable {
                            let scriptSig: ScriptSig
                            let sequence: UInt
                            let txid: String
                            let vout: UInt
                            
                            public struct ScriptSig: Decodable, Sendable {
                                let asm: String
                                let hex: String
                            }
                        }
                        
                        public struct Output: Decodable, Sendable {
                            let n: UInt
                            let scriptPubKey: ScriptPubKey
                            let value: Double
                            
                            public struct ScriptPubKey: Decodable, Sendable {
                                let addresses: [String]?
                                let asm: String
                                let hex: String
                                let reqSigs: UInt?
                                let type: String
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
                    let block_hash: String
                    let block_header: String?
                    let block_height: UInt
                }
                
                public typealias GetHeight = UInt
                
                public struct GetMerkle: Decodable, Sendable {
                    let merkle: [String]
                    let block_height: UInt
                    let pos: UInt
                }
                
                public struct IDFromPos: Decodable, Sendable {
                    let merkle: [String]
                    let tx_hash: String
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
                        let dspid: String
                        let txid: String
                        let hex: String
                        let outpoint: Outpoint
                        let descendants: [String]
                        
                        public struct Outpoint: Decodable, Sendable {
                            let txid: String
                            let vout: UInt
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
                    let confirmed_height: UInt?
                    let scripthash: String
                    let value: UInt
                    let token_data: Method.Blockchain.CashTokens.JSON?
                }
            }
        }
        
        public struct Mempool {
            public typealias FeeHistogram = [UInt]
            public typealias GetFeeHistogram = [FeeHistogram]
        }
    }
}
