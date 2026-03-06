import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
            public struct Get: SwiftFulcrum.RPC.ResponseProtocol {
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
                
                public struct Input: Decodable, Sendable {
                    public let scriptSig: ScriptSig
                    public let sequence: UInt
                    public let transactionID: String
                    public let indexNumberOfPreviousTransactionOutput: UInt
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input) {
                        self.scriptSig = ScriptSig(from: json.scriptSig)
                        self.sequence = json.sequence
                        self.transactionID = json.txid
                        self.indexNumberOfPreviousTransactionOutput = json.vout
                    }
                    
                    public struct ScriptSig: Decodable, Sendable {
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        
                        init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input.ScriptSig) {
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                        }
                    }
                }
                
                public struct Output: Decodable, Sendable {
                    public let index: UInt
                    public let scriptPubKey: ScriptPubKey
                    public let value: Double
                    
                    init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output) {
                        self.index = json.n
                        self.scriptPubKey = ScriptPubKey(from: json.scriptPubKey)
                        self.value = json.value
                    }
                    
                    public struct ScriptPubKey: Decodable, Sendable {
                        public let addresses: [String]
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        public let requiredSignatures: UInt
                        public let type: String
                        
                        init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output.ScriptPubKey) {
                            self.addresses = json.addresses ?? .init()
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                            self.requiredSignatures = json.reqSigs ?? 0
                            self.type = json.type
                        }
                    }
                }
                
                public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get
                public init(fromRPC jsonrpc: JSONRPC) throws {
                    switch jsonrpc {
                    case .raw(let raw):
                        throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Expected detailed transaction information; received raw hex string: \(raw)")
                    case .detailed(let detailed):
                        guard let blockHash = detailed.blockhash else { throw SwiftFulcrum.RPC.Response.Result.Error.missingField("blockhash") }
                        guard let blocktime = detailed.blocktime else { throw SwiftFulcrum.RPC.Response.Result.Error.missingField("blocktime") }
                        guard let confirmations = detailed.confirmations else { throw SwiftFulcrum.RPC.Response.Result.Error.missingField("confirmations") }
                        guard let time = detailed.time else { throw SwiftFulcrum.RPC.Response.Result.Error.missingField("time") }
                        
                        self.blockHash = blockHash
                        self.blocktime = blocktime
                        self.confirmations = confirmations
                        self.hash = detailed.hash
                        self.hex = detailed.hex
                        self.locktime = detailed.locktime
                        self.size = detailed.size
                        self.time = time
                        self.transactionID = detailed.txid
                        self.version = detailed.version
                        self.inputs = detailed.vin.map { Input(from: $0) }
                        self.outputs = detailed.vout.map { Output(from: $0) }
                    }
                }
            }
            

}
