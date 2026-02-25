import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
            public struct GetModel: JSONRPCResponse {
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
                public let inputs: [InputModel]
                public let outputs: [OutputModel]
                
                public struct InputModel: Decodable, Sendable {
                    public let scriptSig: ScriptSigModel
                    public let sequence: UInt
                    public let transactionID: String
                    public let indexNumberOfPreviousTransactionOutput: UInt
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.InputModel) {
                        self.scriptSig = ScriptSigModel(from: json.scriptSig)
                        self.sequence = json.sequence
                        self.transactionID = json.txid
                        self.indexNumberOfPreviousTransactionOutput = json.vout
                    }
                    
                    public struct ScriptSigModel: Decodable, Sendable {
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        
                        init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.InputModel.ScriptSigModel) {
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                        }
                    }
                }
                
                public struct OutputModel: Decodable, Sendable {
                    public let index: UInt
                    public let scriptPubKey: ScriptPubKeyModel
                    public let value: Double
                    
                    init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.OutputModel) {
                        self.index = json.n
                        self.scriptPubKey = ScriptPubKeyModel(from: json.scriptPubKey)
                        self.value = json.value
                    }
                    
                    public struct ScriptPubKeyModel: Decodable, Sendable {
                        public let addresses: [String]
                        public let assemblyScriptLanguage: String
                        public let hex: String
                        public let requiredSignatures: UInt
                        public let type: String
                        
                        init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel.DetailedModel.OutputModel.ScriptPubKeyModel) {
                            self.addresses = json.addresses ?? .init()
                            self.assemblyScriptLanguage = json.asm
                            self.hex = json.hex
                            self.requiredSignatures = json.reqSigs ?? 0
                            self.type = json.type
                        }
                    }
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.GetModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .raw(let raw):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected detailed transaction information; received raw hex string: \(raw)")
                    case .detailed(let detailed):
                        guard let blockHash = detailed.blockhash else { throw FulcrumResponse.ResultModel.Error.missingField("blockhash") }
                        guard let blocktime = detailed.blocktime else { throw FulcrumResponse.ResultModel.Error.missingField("blocktime") }
                        guard let confirmations = detailed.confirmations else { throw FulcrumResponse.ResultModel.Error.missingField("confirmations") }
                        guard let time = detailed.time else { throw FulcrumResponse.ResultModel.Error.missingField("time") }
                        
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
                        self.inputs = detailed.vin.map { InputModel(from: $0) }
                        self.outputs = detailed.vout.map { OutputModel(from: $0) }
                    }
                }
            }
            

}
