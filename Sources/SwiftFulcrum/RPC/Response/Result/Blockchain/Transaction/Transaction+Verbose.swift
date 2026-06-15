// Transaction+Verbose.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct Verbose: Decodable, Sendable {
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
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected detailed transaction information; received raw transaction hex payload with \(raw.utf8.count) UTF-8 bytes"
                )
            case .detailed(let detailed):
                if let blockHash = detailed.blockhash {
                    try SwiftFulcrum.Response.Blockchain.validateBlockHash(blockHash)
                }
                try SwiftFulcrum.Response.Blockchain.validateTransactionHash(detailed.hash)
                try SwiftFulcrum.Response.Blockchain.validateTransactionHash(detailed.txid)
                try SwiftFulcrum.Response.Blockchain.validateNonEmptyHexString(detailed.hex, description: "transaction hex")
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
                self.inputs = try detailed.vin.map { try Input(from: $0) }
                self.outputs = try detailed.vout.map { try Output(from: $0) }
            }
        }
    }
}
