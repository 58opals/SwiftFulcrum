import Foundation

extension Response { public struct Result {} }

extension Response.Result {
    public struct Blockchain {
        public struct EstimateFee: FulcrumRegularResponseResultInitializable {
            typealias JSONRPC = EstimateFeeJSONRPCResult
            
            public let fee: Double
            
            init(jsonrpcResult: JSONRPC) {
                self.fee = jsonrpcResult
            }
        }
        
        public struct RelayFee: FulcrumRegularResponseResultInitializable {
            typealias JSONRPC = EstimateFeeJSONRPCResult
            
            public let fee: Double
            
            init(jsonrpcResult: JSONRPC) {
                self.fee = jsonrpcResult
            }
        }
        
        public struct Address {
            public struct GetBalance: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetBalanceJSONRPCResult
                
                public let confirmed: UInt64
                public let unconfirmed: Int64
                
                init(jsonrpcResult: JSONRPC) {
                    self.confirmed = jsonrpcResult.confirmed
                    self.unconfirmed = jsonrpcResult.unconfirmed
                }
            }
            
            public struct GetFirstUse: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetFirstUseJSONRPCResult
                
                public let blockHash: String
                public let height: UInt
                public let transactionHash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.blockHash = jsonrpcResult.block_hash
                    self.height = jsonrpcResult.height
                    self.transactionHash = jsonrpcResult.tx_hash
                }
            }
            
            public struct GetHistory: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = [GetHistoryJSONRPCResult]
                
                public let transactions: [Transaction]
                public struct Transaction: Decodable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.transactions = jsonrpcResult.map { Transaction(height: $0.height, transactionHash: $0.tx_hash, fee: $0.fee) }
                }
            }
            
            public struct GetMempool: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = [GetMempoolJSONRPCResult]
                
                public let transactions: [Transaction]
                public struct Transaction: Decodable {
                    public let height: Int
                    public let transactionHash: String
                    public let fee: UInt?
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.transactions = jsonrpcResult.map { Transaction(height: $0.height, transactionHash: $0.tx_hash, fee: $0.fee) }
                }
            }
            
            public struct GetScriptHash: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetScriptHashJSONRPCResult
                
                public let hash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.hash = jsonrpcResult
                }
            }
            
            public struct ListUnspent: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = ListUnspentJSONRPCResult
                
                public let items: [Item]
                
                public struct Item: Decodable {
                    public let height: UInt
                    public let tokenData: Method.Blockchain.CashTokens.JSON?
                    public let transactionHash: String
                    public let transactionPosition: UInt
                    public let value: UInt64
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.items = jsonrpcResult.map { Item(height: $0.height,
                                                          tokenData: $0.token_data,
                                                          transactionHash: $0.tx_hash,
                                                          transactionPosition: $0.tx_pos,
                                                          value: $0.value) }
                }
            }
            
            public struct Subscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCResult
                
                public let status: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.status = jsonrpcResult
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                public let subscriptionIdentifier: String
                public let status: String?
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult.address
                    self.status = jsonrpcResult.status
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                public let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
        }
        
        public struct Block {
            public struct Header: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = HeaderJSONRPCResult
                
                public let branch: [String]
                public let header: String
                public let root: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.branch = jsonrpcResult.branch
                    self.header = jsonrpcResult.header
                    self.root = jsonrpcResult.root
                }
            }
            
            public struct Headers: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = HeadersJSONRPCResult
                
                public let count: UInt
                public let hex: String
                public let max: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.count = jsonrpcResult.count
                    self.hex = jsonrpcResult.hex
                    self.max = jsonrpcResult.max
                }
            }
        }
        
        public struct Header {
            public struct Get: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetJSONRPCResult
                
                public let height: UInt
                public let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
        }
        
        public struct Headers {
            public struct GetTip: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetTipJSONRPCResult
                
                public let height: UInt
                public let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
            
            public struct Subscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCResult
                
                public let height: UInt
                public let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                public let subscriptionIdentifier: String
                public let block: Block
                
                public struct Block: Decodable {
                    public let height: UInt
                    public let hex: String
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult[0].hex
                    self.block = .init(height: jsonrpcResult[0].height, hex: jsonrpcResult[0].hex)
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                public let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
        }
        
        public struct Transaction {
            public struct Broadcast: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = BroadcastJSONRPCResult
                
                public let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
            
            public struct Get: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetJSONRPCResult
                
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
                
                init(jsonrpcResult: JSONRPC) {
                    self.blockHash = jsonrpcResult.blockhash
                    self.blocktime = jsonrpcResult.blocktime
                    self.confirmations = jsonrpcResult.confirmations
                    self.hash = jsonrpcResult.hash
                    self.hex = jsonrpcResult.hex
                    self.locktime = jsonrpcResult.locktime
                    self.size = jsonrpcResult.size
                    self.time = jsonrpcResult.time
                    self.transactionID = jsonrpcResult.txid
                    self.version = jsonrpcResult.version
                    self.inputs = jsonrpcResult.vin.map { Input(scriptSig: .init(assemblyScriptLanguage: $0.scriptSig.asm,
                                                                                 hex: $0.scriptSig.hex),
                                                                sequence: $0.sequence,
                                                                transactionID: $0.txid,
                                                                indexNumberOfPreviousTransactionOutput: $0.vout) }
                    self.outputs = jsonrpcResult.vout.map { Output(index: $0.n,
                                                                   scriptPubKey: .init(addresses: $0.scriptPubKey.addresses,
                                                                                       assemblyScriptLanguage: $0.scriptPubKey.asm,
                                                                                       hex: $0.scriptPubKey.hex,
                                                                                       requiredSignatures: $0.scriptPubKey.reqSigs,
                                                                                       type: $0.scriptPubKey.type),
                                                                   value: $0.value) }
                }
            }
            
            public struct GetConfirmedBlockHash: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetConfirmedBlockHashJSONRPCResult
                
                public let blockHash: String
                public let blockHeader: String?
                public let blockHeight: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.blockHash = jsonrpcResult.block_hash
                    self.blockHeader = jsonrpcResult.block_header
                    self.blockHeight = jsonrpcResult.block_height
                }
            }
            
            public struct GetHeight: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetHeightJSONRPCResult
                
                public let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult
                }
            }
            
            public struct GetMerkle: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetMerkleJSONRPCResult
                
                public let merkle: [String]
                public let blockHeight: UInt
                public let position: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.merkle = jsonrpcResult.merkle
                    self.blockHeight = jsonrpcResult.block_height
                    self.position = jsonrpcResult.pos
                }
            }
            
            public struct IDFromPos: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = IDFromPosJSONRPCResult
                
                public let merkle: [String]
                public let transactionHash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.merkle = jsonrpcResult.merkle
                    self.transactionHash = jsonrpcResult.tx_hash
                }
            }
            
            public struct Subscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCResult
                
                public let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult.transactionHash
                    self.transactionHash = jsonrpcResult.transactionHash
                    self.height = jsonrpcResult.height
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                public let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
            
            public struct DSProof {
                public struct Get: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = GetJSONRPCResult
                    
                    public let dspID: String
                    public let transactionID: String
                    public let hex: String
                    public let outpoint: Outpoint
                    public let descendants: [String]
                    
                    public struct Outpoint: Decodable {
                        public let transactionID: String
                        public let vout: UInt
                    }
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.dspID = jsonrpcResult.dspid
                        self.transactionID = jsonrpcResult.txid
                        self.hex = jsonrpcResult.hex
                        self.outpoint = .init(transactionID: jsonrpcResult.outpoint.txid,
                                              vout: jsonrpcResult.outpoint.vout)
                        self.descendants = jsonrpcResult.descendants
                    }
                }
                
                public struct List: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = ListJSONRPCResult
                    
                    public let transactionHashes: [String]
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.transactionHashes = jsonrpcResult
                    }
                }
                
                public struct Subscribe: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = SubscribeJSONRPCResult
                    
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
                    
                    init(jsonrpcResult: JSONRPC) {
                        // print(jsonrpcResult)
                        self.proof = .init(dspID: jsonrpcResult.proof.dspid,
                                           transactionID: jsonrpcResult.proof.txid,
                                           hex: jsonrpcResult.proof.hex,
                                           outpoint: .init(transactionID: jsonrpcResult.proof.outpoint.txid,
                                                           vout: jsonrpcResult.proof.outpoint.vout),
                                           descendants: jsonrpcResult.proof.descendants)
                    }
                }
                
                public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                    typealias JSONRPC = SubscribeJSONRPCNotification
                    
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
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.subscriptionIdentifier = jsonrpcResult.transactionHash
                        self.transactionHash = jsonrpcResult.transactionHash
                        if let proof = jsonrpcResult.dsProof {
                            self.proof = .init(dspID: proof.dspid,
                                               transactionID: proof.txid,
                                               hex: proof.hex,
                                               outpoint: .init(transactionID: proof.outpoint.txid,
                                                               vout: proof.outpoint.vout),
                                               descendants: proof.descendants)
                        } else {
                            self.proof = nil
                        }
                    }
                }
                
                public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = UnsubscribeJSONRPCResult
                    
                    public let success: Bool
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.success = jsonrpcResult
                    }
                }
            }
        }
        
        public struct UTXO {
            public struct GetInfo: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetInfoJSONRPCResult
                
                public let confirmedHeight: UInt?
                public let scriptHash: String
                public let value: UInt
                public let tokenData: Method.Blockchain.CashTokens.JSON?
                
                init(jsonrpcResult: JSONRPC) {
                    self.confirmedHeight = jsonrpcResult.confirmed_height
                    self.scriptHash = jsonrpcResult.scripthash
                    self.value = jsonrpcResult.value
                    self.tokenData = jsonrpcResult.token_data
                }
            }
        }
    }
    
    public struct Mempool {
        public struct GetFeeHistogram: FulcrumRegularResponseResultInitializable {
            typealias JSONRPC = GetFeeHistogramJSONRPCResult
            
            public struct Result: Decodable {
                public let fee: UInt
                public let virtualSize: UInt
            }
            
            public let histogram: [Result]
            
            init(jsonrpcResult: JSONRPC) {
                self.histogram = .init()
            }
        }
    }
}
