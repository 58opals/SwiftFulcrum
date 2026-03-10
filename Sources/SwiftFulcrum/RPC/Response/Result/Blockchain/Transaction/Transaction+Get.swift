// Transaction+Get.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct Get: Decodable, Sendable {
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

            init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input) {
                self.scriptSig = ScriptSig(from: payloadModel.scriptSig)
                self.sequence = payloadModel.sequence
                self.transactionID = payloadModel.txid
                self.indexNumberOfPreviousTransactionOutput = payloadModel.vout
            }

            public struct ScriptSig: Decodable, Sendable {
                public let assemblyScriptLanguage: String
                public let hex: String

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Input.ScriptSig) {
                    self.assemblyScriptLanguage = payloadModel.asm
                    self.hex = payloadModel.hex
                }
            }
        }

        public struct Output: Decodable, Sendable {
            public let index: UInt
            public let scriptPubKey: ScriptPubKey
            public let value: Double

            init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output) {
                self.index = payloadModel.n
                self.scriptPubKey = ScriptPubKey(from: payloadModel.scriptPubKey)
                self.value = payloadModel.value
            }

            public struct ScriptPubKey: Decodable, Sendable {
                public let addresses: [String]
                public let assemblyScriptLanguage: String
                public let hex: String
                public let requiredSignatures: UInt
                public let type: String

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output.ScriptPubKey) {
                    self.addresses = payloadModel.addresses ?? .init()
                    self.assemblyScriptLanguage = payloadModel.asm
                    self.hex = payloadModel.hex
                    self.requiredSignatures = payloadModel.reqSigs ?? 0
                    self.type = payloadModel.type
                }
            }
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get(from: decoder)
            switch payloadModel {
            case .raw(let raw):
                throw ResponseResultDecodeError.unexpectedFormat("Expected detailed transaction information; received raw hex string: \(raw)")
            case .detailed(let detailed):
                guard let blockHash = detailed.blockhash else { throw ResponseResultDecodeError.missingField("blockhash") }
                guard let blocktime = detailed.blocktime else { throw ResponseResultDecodeError.missingField("blocktime") }
                guard let confirmations = detailed.confirmations else { throw ResponseResultDecodeError.missingField("confirmations") }
                guard let time = detailed.time else { throw ResponseResultDecodeError.missingField("time") }

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
                self.inputs = detailed.vin.map(Input.init(from:))
                self.outputs = detailed.vout.map(Output.init(from:))
            }
        }
    }
}
