// Method.Blockchain+Header.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    enum Header: Sendable {
        case get(blockHash: String)
    }
}
