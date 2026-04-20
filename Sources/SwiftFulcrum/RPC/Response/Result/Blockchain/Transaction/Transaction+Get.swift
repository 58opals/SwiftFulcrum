// Transaction+Get.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct Get: Decodable, Sendable {
        public let blockHash: String?
        public let blocktime: UInt?
        public let confirmations: UInt?
        public let hash: String
        public let hex: String
        public let locktime: UInt
        public let size: UInt
        public let time: UInt?
        public let transactionID: String
        public let version: UInt
        public let inputs: [Input]
        public let outputs: [Output]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Get(from: decoder)
            switch payloadModel {
            case .raw(let raw):
                throw ResponseResultDecodeError.unexpectedFormat("Expected detailed transaction information; received raw hex string: \(raw)")
            case .detailed(let detailed):
                self.blockHash = detailed.blockhash
                self.blocktime = detailed.blocktime
                self.confirmations = detailed.confirmations
                self.hash = detailed.hash
                self.hex = detailed.hex
                self.locktime = detailed.locktime
                self.size = detailed.size
                self.time = detailed.time
                self.transactionID = detailed.txid
                self.version = detailed.version
                self.inputs = detailed.vin.map(Input.init(from:))
                self.outputs = detailed.vout.map(Output.init(from:))
            }
        }
    }
}
