// Response+Result.swift

import Foundation

extension Response { struct Result {} }

extension Response.Result {
    struct Blockchain {
        struct EstimateFee: Decodable {
            let fee: Double
        }
        
        struct RelayFee: Decodable {
            let fee: Double
        }
        
        struct Address {
            struct GetBalance: Decodable {
                let confirmed: UInt64
                let unconfirmed: Int64
            }
            
            struct GetFirstUse: Decodable {
                let blockHash: String
                let height: UInt
                let transactionHash: String
            }
            
            struct GetHistory: Decodable {
                let transactions: [Transaction]
                struct Transaction: Decodable {
                    let height: Int
                    let transactionHash: String
                    let fee: UInt?
                }
            }
            
            struct GetMempool: Decodable {
                let transactions: [Transaction]
                struct Transaction: Decodable {
                    let height: Int
                    let transactionHash: String
                    let fee: UInt?
                }
            }
            
            struct GetScriptHash: Decodable {
                let hash: String
            }
            
            struct ListUnspent: Decodable {
                let items: [Item]
                
                struct Item: Decodable {
                    let height: UInt
                    let tokenData: Method.Blockchain.CashTokens.JSON?
                    let transactionHash: String
                    let transactionPosition: UInt
                    let value: UInt64
                }
            }
            
            struct Subscribe: Decodable {
                let status: String
            }
            
            struct SubscribeNotification: Decodable {
                let subscriptionIdentifier: String
                let status: String?
            }
            
            struct Unsubscribe: Decodable {
                let success: Bool
            }
        }
        
        struct Block {
            struct Header: Decodable {
                let branch: [String]
                let header: String
                let root: String
            }
            
            struct Headers: Decodable {
                let count: UInt
                let hex: String
                let max: UInt
            }
        }
        
        struct Header {
            struct Get: Decodable {
                let height: UInt
                let hex: String
            }
        }
        
        struct Headers {
            struct GetTip: Decodable {
                let height: UInt
                let hex: String
            }
            
            struct Subscribe: Decodable {
                let height: UInt
                let hex: String
            }
            
            struct SubscribeNotification: Decodable {
                let subscriptionIdentifier: String
                let block: Block
                
                struct Block: Decodable {
                    let height: UInt
                    let hex: String
                }
            }
            
            struct Unsubscribe: Decodable {
                let success: Bool
            }
        }
        
        struct Transaction {
            struct Broadcast: Decodable {
                let transactionHash: Data
            }
            
            struct Get: Decodable {
                let blockHash: String
                let blocktime: UInt
                let confirmations: UInt
                let hash: String
                let hex: String
                let locktime: UInt
                let size: UInt
                let time: UInt
                let transactionID: String
                let version: UInt
                let inputs: [Input]
                let outputs: [Output]
                
                struct Input: Decodable {
                    let scriptSig: ScriptSig
                    let sequence: UInt
                    let transactionID: String
                    let indexNumberOfPreviousTransactionOutput: UInt
                    
                    struct ScriptSig: Decodable {
                        let assemblyScriptLanguage: String
                        let hex: String
                    }
                }
                
                struct Output: Decodable {
                    let index: UInt
                    let scriptPubKey: ScriptPubKey
                    let value: Double
                    
                    struct ScriptPubKey: Decodable {
                        let addresses: [String]
                        let assemblyScriptLanguage: String
                        let hex: String
                        let requiredSignatures: UInt
                        let type: String
                    }
                }
            }
            
            struct GetConfirmedBlockHash: Decodable {
                let blockHash: String
                let blockHeader: String?
                let blockHeight: UInt
            }
            
            struct GetHeight: Decodable {
                let height: UInt
            }
            
            struct GetMerkle: Decodable {
                let merkle: [String]
                let blockHeight: UInt
                let position: UInt
            }
            
            struct IDFromPos: Decodable {
                let merkle: [String]
                let transactionHash: String
            }
            
            struct Subscribe: Decodable {
                let height: UInt
            }
            
            struct SubscribeNotification: Decodable {
                let subscriptionIdentifier: String
                let transactionHash: String
                let height: UInt
            }
            
            struct Unsubscribe: Decodable {
                let success: Bool
            }
            
            struct DSProof {
                struct Get: Decodable {
                    let dspID: String
                    let transactionID: String
                    let hex: String
                    let outpoint: Outpoint
                    let descendants: [String]
                    
                    struct Outpoint: Decodable {
                        let transactionID: String
                        let vout: UInt
                    }
                }
                
                struct List: Decodable {
                    let transactionHashes: [String]
                }
                
                struct Subscribe: Decodable {
                    let proof: Proof
                    
                    struct Proof: Decodable {
                        let dspID: String
                        let transactionID: String
                        let hex: String
                        let outpoint: Outpoint
                        let descendants: [String]
                        
                        struct Outpoint: Decodable {
                            let transactionID: String
                            let vout: UInt
                        }
                    }
                }
                
                struct SubscribeNotification: Decodable {
                    let subscriptionIdentifier: String
                    let transactionHash: String
                    let proof: Proof?
                    
                    struct Proof: Decodable {
                        let dspID: String
                        let transactionID: String
                        let hex: String
                        let outpoint: Outpoint
                        let descendants: [String]
                        
                        struct Outpoint: Decodable {
                            let transactionID: String
                            let vout: UInt
                        }
                    }
                }
                
                struct Unsubscribe: Decodable {
                    let success: Bool
                }
            }
        }
        
        struct UTXO {
            struct GetInfo: Decodable {
                let confirmedHeight: UInt?
                let scriptHash: String
                let value: UInt
                let tokenData: Method.Blockchain.CashTokens.JSON?
            }
        }
    }
    
    struct Mempool {
        struct GetFeeHistogram: Decodable {
            struct Result: Decodable {
                let fee: UInt
                let virtualSize: UInt
            }
            
            let histogram: [Result]
        }
    }
}
