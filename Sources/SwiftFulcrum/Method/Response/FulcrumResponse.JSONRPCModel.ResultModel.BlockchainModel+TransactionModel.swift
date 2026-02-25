import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
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
            

}
