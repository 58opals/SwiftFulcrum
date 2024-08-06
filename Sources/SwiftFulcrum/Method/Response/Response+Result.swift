import Foundation

extension Response { public struct Result {} }

extension Response.Result {
    public struct Blockchain {
        public struct EstimateFee: Decodable {
            public let fee: Double
        }
        
        public struct RelayFee: Decodable {
            public let fee: Double
        }
        
        public struct Address {
            public struct GetBalance: Decodable {
                public let confirmed: UInt64
                public let unconfirmed: Int64
            }
            
            public struct GetFirstUse: Decodable {
                public let blockHash: String
                public let height: UInt
                public let transactionHash: String
            }
            
            public struct GetHistory: Decodable {
                public let transactions: [Transaction]
                public struct Transaction: Decodable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                }
            }
            
            public struct GetMempool: Decodable {
                public let transactions: [Transaction]
                public struct Transaction: Decodable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                }
            }
            
            public struct GetScriptHash: Decodable {
                public let hash: String
            }
            
            public struct ListUnspent: Decodable {
                public let items: [Item]
                
                public struct Item: Decodable {
                    public let height: UInt
                    public let tokenData: Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                }
            }
            
            public struct Subscribe: Decodable {
                public let status: String
            }
            
            public struct SubscribeNotification: Decodable {
                public let subscriptionIdentifier: String
                public let status: String?
            }
            
            public struct Unsubscribe: Decodable {
                public let success: Bool
            }
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
            
            public struct Subscribe: Decodable {
                public let height: UInt
                public let hex: String
            }
            
            public struct SubscribeNotification: Decodable {
                public let subscriptionIdentifier: String
                public let block: Block
                
                public struct Block: Decodable {
                    public let height: UInt
                    public let hex: String
                }
            }
            
            public struct Unsubscribe: Decodable {
                public let success: Bool
            }
        }
        
        public struct Transaction {
            public struct Broadcast: Decodable {
                public let success: Bool
            }
            
            public struct Get: Decodable {
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
                
                public struct Input: Decodable {
                    public let scriptSig: ScriptSig
                    public let sequence: UInt
                    public let transactionID: String
                    public let indexNumberOfPreviousTransactionOutput: UInt
                    
                    public struct ScriptSig: Decodable {
                        public let assemblyScriptLanguage: String
                        public let hex: String
                    }
                }
                
                public struct Output: Decodable {
                    public let index: UInt
                    public let scriptPubKey: ScriptPubKey
                    public let value: Double
                    
                    public struct ScriptPubKey: Decodable {
                        public let addresses: [String]
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        public let requiredSignatures: UInt
                        public let type: String
                    }
                }
            }
            
            public struct GetConfirmedBlockHash: Decodable {
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
            }
            
            public struct GetHeight: Decodable {
                public let height: UInt
            }
            
            public struct GetMerkle: Decodable {
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
            }
            
            public struct IDFromPos: Decodable {
                public let merkle: [String]
                public let transactionHash: String
            }
            
            public struct Subscribe: Decodable {
                public let height: UInt
            }
            
            public struct SubscribeNotification: Decodable {
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
            }
            
            public struct Unsubscribe: Decodable {
                public let success: Bool
            }
            
            public struct DSProof {
                public struct Get: Decodable {
                    public let dspID: String
                    public let transactionID: String
                    public let hex: String
                    public let outpoint: Outpoint
                    public let descendants: [String]
                    
                    public struct Outpoint: Decodable {
                        public let transactionID: String
                        public let vout: UInt
                    }
                }
                
                public struct List: Decodable {
                    public let transactionHashes: [String]
                }
                
                public struct Subscribe: Decodable {
                    public let proof: Proof
                    
                    public struct Proof: Decodable {
                        public let dspID: String
                        public let transactionID: String
                        public let hex: String
                        public let outpoint: Outpoint
                        public let descendants: [String]
                        
                        public struct Outpoint: Decodable {
                            public let transactionID: String
                            public let vout: UInt
                        }
                    }
                }
                
                public struct SubscribeNotification: Decodable {
                    public let subscriptionIdentifier: String
                    public let transactionHash: String
                    public let proof: Proof?
                    
                    public struct Proof: Decodable {
                        public let dspID: String
                        public let transactionID: String
                        public let hex: String
                        public let outpoint: Outpoint
                        public let descendants: [String]
                        
                        public struct Outpoint: Decodable {
                            public let transactionID: String
                            public let vout: UInt
                        }
                    }
                }
                
                public struct Unsubscribe: Decodable {
                    public let success: Bool
                }
            }
        }
        
        public struct UTXO {
            public struct GetInfo: Decodable {
                public let confirmedHeight: UInt?
                public let scriptHash: String
                public let value: UInt
                public let tokenData: Method.Blockchain.CashTokens.JSON?
            }
        }
    }
    
    public struct Mempool {
        public struct GetFeeHistogram: Decodable {
            public struct Result: Decodable {
                public let fee: UInt
                public let virtualSize: UInt
            }
            
            public let histogram: [Result]
        }
    }
}
