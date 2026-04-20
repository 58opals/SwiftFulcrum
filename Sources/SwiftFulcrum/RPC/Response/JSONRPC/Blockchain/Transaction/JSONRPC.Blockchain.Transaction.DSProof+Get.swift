// JSONRPC.Blockchain.Transaction.DSProof+Get.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof {
    struct Get: Decodable, Sendable {
        let dspid: String
        let txid: String
        let hex: String
        let outpoint: Outpoint
        let descendants: [String]
    }
}
