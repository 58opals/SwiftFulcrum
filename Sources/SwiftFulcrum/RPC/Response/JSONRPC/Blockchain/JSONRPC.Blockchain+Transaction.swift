// JSONRPC.Blockchain+Transaction.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct Transaction {
        typealias Broadcast = String

        typealias Get = GetParameters
        enum GetParameters: Decodable, Sendable {
                    case raw(String)
                    case detailed(Detailed)
                    
            struct Detailed: Decodable, Sendable {
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

                struct Input: Decodable, Sendable {
                    let coinbase: String?
                    let scriptSig: ScriptSig?
                    let sequence: UInt
                    let txid: String?
                    let vout: UInt?

                    struct ScriptSig: Decodable, Sendable {
                        let asm: String
                        let hex: String
                            }
                        }
                        
                struct Output: Decodable, Sendable {
                    let n: UInt
                    let scriptPubKey: ScriptPubKey
                    let value: Double

                    struct ScriptPubKey: Decodable, Sendable {
                        let address: String?
                        let addresses: [String]?
                        let asm: String
                        let hex: String
                        let reqSigs: UInt?
                        let type: String
                            }
                        }
                    }
                    
            init(from decoder: Decoder) throws {
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

        struct GetConfirmedBlockHash: Decodable, Sendable {
            let block_hash: String
            let block_header: String?
            let block_height: UInt
        }

        typealias GetHeight = UInt

        struct GetMerkle: Decodable, Sendable {
            let merkle: [String]
            let block_height: UInt
            let pos: UInt
        }

        typealias IDFromPos = IDFromPosParameters
        enum IDFromPosParameters: Decodable, Sendable {
            case transactionHash(String)
            case merkleProof(MerkleProof)

            struct MerkleProof: Decodable, Sendable {
                let merkle: [String]
                let tx_hash: String
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                if let transactionHash = try? container.decode(String.self) {
                    self = .transactionHash(transactionHash)
                    return
                }

                if let merkleProof = try? container.decode(MerkleProof.self) {
                    self = .merkleProof(merkleProof)
                    return
                }

                throw DecodingError.typeMismatch(
                    IDFromPosParameters.self,
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected transaction hash string or merkle proof object"
                    )
                )
            }
        }

        typealias Subscribe = SubscribeParameters
        enum SubscribeParameters: Decodable, Sendable {
                    case height(UInt)
                    case transactionHashAndHeight([TransactionHashAndHeight])
                    
                    enum TransactionHashAndHeight: Decodable, Sendable {
                        case transactionHash(String)
                        case height(UInt)
                        
                        init(from decoder: Decoder) throws {
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
                    
                    init(from decoder: Decoder) throws {
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

        typealias Unsubscribe = Bool

        struct DSProof {
            struct Get: Decodable, Sendable {
                let dspid: String
                let txid: String
                let hex: String
                let outpoint: Outpoint
                let descendants: [String]

                struct Outpoint: Decodable, Sendable {
                    let txid: String
                    let vout: UInt
                }
            }

            typealias List = [String]

            typealias Subscribe = SubscribeParameters
            enum SubscribeParameters: Decodable, Sendable {
                        case dsProof(Get?)
                        case transactionHashAndDSProof([TransactionHashAndDS])
                        
                        enum TransactionHashAndDS: Decodable, Sendable {
                            case transactionHash(String)
                            case dsProof(Get)
                            
                            init(from decoder: Decoder) throws {
                                let container = try decoder.singleValueContainer()
                                
                                if let stringResult = try? container.decode(String.self) {
                                    self = .transactionHash(stringResult)
                                    return
                                }
                                
                                if let getResult = try? container.decode(Get.self) {
                                    self = .dsProof(getResult)
                                    return
                                }
                                
                                throw DecodingError.typeMismatch(TransactionHashAndDS.self,
                                                                 .init(codingPath: decoder.codingPath,
                                                                       debugDescription: "Expected transaction hash or double-spending proof"))
                            }
                        }
                        
                        init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            
                            if container.decodeNil() {
                                self = .dsProof(nil)
                                return
                            }
                            
                            if let getResult = try? container.decode(Get?.self) {
                                self = .dsProof(getResult)
                                return
                            }
                            
                            if let stringAndUGetResult = try? container.decode([TransactionHashAndDS].self) {
                                self = .transactionHashAndDSProof(stringAndUGetResult)
                                return
                            }
                            
                            throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                             .init(codingPath: decoder.codingPath,
                                                                   debugDescription: "Expected nil, a DSProof, or [txHash, dsProof]"))
                        }
            }

            typealias Unsubscribe = Bool
        }
    }
}
