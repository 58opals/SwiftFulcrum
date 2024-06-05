import Foundation

extension Response { public struct Result {} }

extension Response.Result {
    public struct Blockchain {
        public struct EstimateFee: FulcrumRegularResponseResultInitializable {
            typealias JSONRPC = EstimateFeeJSONRPCResult
            
            let fee: Double
            
            init(jsonrpcResult: JSONRPC) {
                self.fee = jsonrpcResult
            }
        }
        
        public struct RelayFee: FulcrumRegularResponseResultInitializable {
            typealias JSONRPC = EstimateFeeJSONRPCResult
            
            let fee: Double
            
            init(jsonrpcResult: JSONRPC) {
                self.fee = jsonrpcResult
            }
        }
        
        public struct Address {
            public struct GetBalance: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetBalanceJSONRPCResult
                
                let confirmed: UInt64
                let unconfirmed: Int64
                
                init(jsonrpcResult: JSONRPC) {
                    self.confirmed = jsonrpcResult.confirmed
                    self.unconfirmed = jsonrpcResult.unconfirmed
                }
            }
            
            public struct GetFirstUse: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetFirstUseJSONRPCResult
                
                let blockHash: String
                let height: UInt
                let transactionHash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.blockHash = jsonrpcResult.block_hash
                    self.height = jsonrpcResult.height
                    self.transactionHash = jsonrpcResult.tx_hash
                }
            }
            
            public struct GetHistory: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = [GetHistoryJSONRPCResult]
                
                let transactions: [Transaction]
                struct Transaction: Decodable {
                    let height: Int
                    let transactionHash: String
                    let fee: UInt?
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.transactions = jsonrpcResult.map { Transaction(height: $0.height, transactionHash: $0.tx_hash, fee: $0.fee) }
                }
            }
            
            public struct GetMempool: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = [GetMempoolJSONRPCResult]
                
                let transactions: [Transaction]
                struct Transaction: Decodable {
                    let height: Int
                    let transactionHash: String
                    let fee: UInt?
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.transactions = jsonrpcResult.map { Transaction(height: $0.height, transactionHash: $0.tx_hash, fee: $0.fee) }
                }
            }
            
            public struct GetScriptHash: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetScriptHashJSONRPCResult
                
                let hash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.hash = jsonrpcResult
                }
            }
            
            public struct ListUnspent: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = ListUnspentJSONRPCResult
                
                let items: [Item]
                
                struct Item: Decodable {
                    let height: UInt
                    let tokenData: Method.Blockchain.CashTokens.JSON?
                    let transactionHash: String
                    let transactionPosition: UInt
                    let value: UInt64
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
                
                let status: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.status = jsonrpcResult
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                let subscriptionIdentifier: String
                let status: String?
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult.address
                    self.status = jsonrpcResult.status
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
        }
        
        public struct Block {
            public struct Header: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = HeaderJSONRPCResult
                
                let branch: [String]
                let header: String
                let root: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.branch = jsonrpcResult.branch
                    self.header = jsonrpcResult.header
                    self.root = jsonrpcResult.root
                }
            }
            
            public struct Headers: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = HeadersJSONRPCResult
                
                let count: UInt
                let hex: String
                let max: UInt
                
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
                
                let height: UInt
                let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
        }
        
        public struct Headers {
            public struct GetTip: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetTipJSONRPCResult
                
                let height: UInt
                let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
            
            public struct Subscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCResult
                
                let height: UInt
                let hex: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult.height
                    self.hex = jsonrpcResult.hex
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                let subscriptionIdentifier: String
                let block: Block
                struct Block: Decodable {
                    let height: UInt
                    let hex: String
                }
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult[0].hex
                    self.block = .init(height: jsonrpcResult[0].height, hex: jsonrpcResult[0].hex)
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
        }
        
        public struct Transaction {
            public struct Broadcast: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = BroadcastJSONRPCResult
                
                let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
            
            public struct Get: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetJSONRPCResult
                
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
                
                let blockHash: String
                let blockHeader: String?
                let blockHeight: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.blockHash = jsonrpcResult.block_hash
                    self.blockHeader = jsonrpcResult.block_header
                    self.blockHeight = jsonrpcResult.block_height
                }
            }
            
            public struct GetHeight: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetHeightJSONRPCResult
                
                let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult
                }
            }
            
            public struct GetMerkle: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetMerkleJSONRPCResult
                
                let merkle: [String]
                let blockHeight: UInt
                let position: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.merkle = jsonrpcResult.merkle
                    self.blockHeight = jsonrpcResult.block_height
                    self.position = jsonrpcResult.pos
                }
            }
            
            public struct IDFromPos: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = IDFromPosJSONRPCResult
                
                let merkle: [String]
                let transactionHash: String
                
                init(jsonrpcResult: JSONRPC) {
                    self.merkle = jsonrpcResult.merkle
                    self.transactionHash = jsonrpcResult.tx_hash
                }
            }
            
            public struct Subscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCResult
                
                let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.height = jsonrpcResult
                }
            }
            
            public struct SubscribeNotification: FulcrumSubscriptionResponseResultInitializable {
                typealias JSONRPC = SubscribeJSONRPCNotification
                
                let subscriptionIdentifier: String
                let transactionHash: String
                let height: UInt
                
                init(jsonrpcResult: JSONRPC) {
                    self.subscriptionIdentifier = jsonrpcResult.transactionHash
                    self.transactionHash = jsonrpcResult.transactionHash
                    self.height = jsonrpcResult.height
                }
            }
            
            public struct Unsubscribe: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = UnsubscribeJSONRPCResult
                
                let success: Bool
                
                init(jsonrpcResult: JSONRPC) {
                    self.success = jsonrpcResult
                }
            }
            
            public struct DSProof {
                public struct Get: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = GetJSONRPCResult
                    
                    let dspID: String
                    let transactionID: String
                    let hex: String
                    let outpoint: Outpoint
                    let descendants: [String]
                    
                    struct Outpoint: Decodable {
                        let transactionID: String
                        let vout: UInt
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
                    
                    let transactionHashes: [String]
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.transactionHashes = jsonrpcResult
                    }
                }
                
                public struct Subscribe: FulcrumRegularResponseResultInitializable {
                    typealias JSONRPC = SubscribeJSONRPCResult
                    
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
                    
                    init(jsonrpcResult: JSONRPC) {
                        print(jsonrpcResult)
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
                    
                    let success: Bool
                    
                    init(jsonrpcResult: JSONRPC) {
                        self.success = jsonrpcResult
                    }
                }
            }
        }
        
        public struct UTXO {
            public struct GetInfo: FulcrumRegularResponseResultInitializable {
                typealias JSONRPC = GetInfoJSONRPCResult
                
                let confirmedHeight: UInt?
                let scriptHash: String
                let value: UInt
                let tokenData: Method.Blockchain.CashTokens.JSON?
                
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
            
            struct Result: Decodable {
                let fee: UInt
                let virtualSize: UInt
            }
            
            let histogram: [Result]
            
            init(jsonrpcResult: JSONRPC) {
                self.histogram = .init()
            }
        }
    }
}
