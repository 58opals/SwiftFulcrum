// Method.Blockchain+Transaction.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    public enum Transaction: Sendable {
        case broadcast(rawTransaction: String)
        case get(transactionHash: String, isVerbose: Bool)
        case getConfirmedBlockHash(transactionHash: String, shouldIncludeHeader: Bool)
        case getHeight(transactionHash: String)
        case getMerkle(transactionHash: String)
        case idFromPos(blockHeight: UInt, transactionPosition: UInt, shouldIncludeMerkleProof: Bool)
        case subscribe(transactionHash: String)
        case unsubscribe(transactionHash: String)
        case dsProof(DSProof)
    }
}
