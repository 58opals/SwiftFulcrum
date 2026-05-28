// Transaction.Verbose.Output+ScriptPubKey.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction.Verbose.Output {
    public struct ScriptPubKey: Decodable, Sendable {
        public let addresses: [String]
        public let assemblyScriptLanguage: String
        public let hex: String
        public let requiredSignatures: UInt
        public let type: String

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get.Detailed.Output.ScriptPubKey) throws {
            try SwiftFulcrum.Response.Blockchain.validateHexString(payloadModel.hex, description: "scriptPubKey hex")
            if let addresses = payloadModel.addresses {
                self.addresses = addresses
            } else if let address = payloadModel.address {
                self.addresses = [address]
            } else {
                self.addresses = .init()
            }
            self.assemblyScriptLanguage = payloadModel.asm
            self.hex = payloadModel.hex
            self.requiredSignatures = payloadModel.reqSigs ?? 0
            self.type = payloadModel.type
        }
    }
}
