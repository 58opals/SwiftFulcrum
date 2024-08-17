import Foundation

extension Response.JSONRPC {
    public struct Result {
        public struct Blockchain {
            public typealias EstimateFee = Double
            
            public typealias RelayFee = Double
            
            public struct Address {
                public struct GetBalance: Decodable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUse: Decodable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistory = [GetHistoryItem]
                public struct GetHistoryItem: Decodable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempool = [GetMempoolItem]
                public struct GetMempoolItem: Decodable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetScriptHash = String
                
                public typealias ListUnspent = [ListUnspentItem]
                public struct ListUnspentItem: Decodable {
                    public let height: UInt
                    public let token_data: Method.Blockchain.CashTokens.JSON?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable {
                    case status(String)
                    case addressAndStatus([String])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) { self = .status(singleValue) }
                        else if let multipleValues = try? container.decode([String].self) { self = .addressAndStatus(multipleValues) }
                        else { throw DecodingError.typeMismatch(SubscribeParameters.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for JSONRPCResult")) }
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            
            public struct Block {
                public struct Header: Decodable {
                    public let branch: [String]
                    public let header: String
                    public let root: String
                }
                
                public struct Headers: Decodable {
                    public let count: UInt
                    public let hex: String
                    public let max: UInt
                }
            }
            
            public struct Header {
                public struct Get: Decodable {
                    public let height: UInt
                    public let hex: String
                }
            }
            
            public struct Headers {
                public struct GetTip: Decodable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable {
                    case topHeader(GetTip)
                    case newHeader([GetTip])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(GetTip.self) { self = .topHeader(singleValue) }
                        else if let multipleValues = try? container.decode([GetTip].self) { self = .newHeader(multipleValues) }
                        else { throw DecodingError.typeMismatch(SubscribeParameters.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for JSONRPCResult")) }
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            
            public struct Transaction {
                public typealias Broadcast = Data
                
                public struct Get: Decodable {
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
                    
                    public struct Input: Decodable {
                        public let scriptSig: ScriptSig
                        public let sequence: UInt
                        public let txid: String
                        public let vout: UInt
                        
                        public struct ScriptSig: Decodable {
                            public let asm: String
                            public let hex: String
                        }
                    }
                    
                    public struct Output: Decodable {
                        public let n: UInt
                        public let scriptPubKey: ScriptPubKey
                        public let value: Double
                        
                        public struct ScriptPubKey: Decodable {
                            public let addresses: [String]
                            public let asm: String
                            public let hex: String
                            public let reqSigs: UInt
                            public let type: String
                        }
                    }
                }
                
                public struct GetConfirmedBlockHash: Decodable {
                    public let block_hash: String
                    public let block_header: String?
                    public let block_height: UInt
                }
                
                public typealias GetHeight = UInt
                
                public struct GetMerkle: Decodable {
                    public let merkle: [String]
                    public let block_height: UInt
                    public let pos: UInt
                }
                
                public struct IDFromPos: Decodable {
                    public let merkle: [String]
                    public let tx_hash: String
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable {
                    case height(UInt)
                    case transactionHashAndHeight([TransactionHashAndHeight])
                    
                    public enum TransactionHashAndHeight: Decodable {
                        case transactionHash(String)
                        case height(UInt)
                        
                        public init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            
                            if let stringResult = try? container.decode(String.self) { self = .transactionHash(stringResult) }
                            else if let uintResult = try? container.decode(UInt.self) { self = .height(uintResult) }
                            else { throw DecodingError.typeMismatch(TransactionHashAndHeight.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for MixedArrayElement")) }
                        }
                    }
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let uintResult = try? container.decode(UInt.self) { self = .height(uintResult) }
                        else if let stringAndUIntResult = try? container.decode([TransactionHashAndHeight].self) { self = .transactionHashAndHeight(stringAndUIntResult)
                        } else { throw DecodingError.typeMismatch(SubscribeParameters.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for JSONRPCResult")) }
                    }
                }
                
                public typealias Unsubscribe = Bool
                
                public struct DSProof {
                    public struct Get: Decodable {
                        public let dspid: String
                        public let txid: String
                        public let hex: String
                        public let outpoint: Outpoint
                        public let descendants: [String]
                        
                        public struct Outpoint: Decodable {
                            public let txid: String
                            public let vout: UInt
                        }
                    }
                    
                    public typealias List = [String]
                    
                    public typealias Subscribe = SubscribeParameters
                    
                    public enum SubscribeParameters: Decodable {
                        case dsProof(Get?)
                        case transactionHashAndDSProof([TransactionHashAndDSProof])
                        
                        public enum TransactionHashAndDSProof: Decodable {
                            case transactionHash(String)
                            case dsProof(Get)
                            
                            public init(from decoder: Decoder) throws {
                                let container = try decoder.singleValueContainer()
                                
                                if let stringResult = try? container.decode(String.self) { self = .transactionHash(stringResult) }
                                else if let getResult = try? container.decode(Get.self) { self = .dsProof(getResult) }
                                else { throw DecodingError.typeMismatch(TransactionHashAndDSProof.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for MixedArrayElement")) }
                            }
                        }
                        
                        public init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            
                            if let getResult = try? container.decode(Get?.self) { self = .dsProof(getResult) }
                            else if let stringAndUGetResult = try? container.decode([TransactionHashAndDSProof].self) { self = .transactionHashAndDSProof(stringAndUGetResult)
                            } else { self = .dsProof(nil) }
                        }
                    }
                    
                    public typealias Unsubscribe = Bool
                }
            }
            
            public struct UTXO {
                public struct GetInfo: Decodable {
                    public let confirmed_height: UInt?
                    public let scripthash: String
                    public let value: UInt
                    public let token_data: Method.Blockchain.CashTokens.JSON?
                }
            }
        }
        
        public struct Mempool {
            public typealias GetFeeHistogram = [[UInt]]
        }
    }
}
