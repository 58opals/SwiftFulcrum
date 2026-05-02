// Method.Blockchain.Transaction+DSProof.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain.Transaction {
    enum DSProof: Sendable {
        case get(transactionHash: String)
        case list
        case subscribe(transactionHash: String)
        case unsubscribe(transactionHash: String)
    }
}
