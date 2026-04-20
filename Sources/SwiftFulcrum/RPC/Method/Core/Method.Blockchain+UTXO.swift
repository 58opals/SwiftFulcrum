// Method.Blockchain+UTXO.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    public enum UTXO: Sendable {
        case getInfo(transactionHash: String, outputIndex: UInt16)
    }
}
