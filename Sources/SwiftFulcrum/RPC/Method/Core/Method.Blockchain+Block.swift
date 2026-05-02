// Method.Blockchain+Block.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    enum Block: Sendable {
        case header(height: UInt, checkpointHeight: UInt? = nil)
        case headers(startHeight: UInt, count: UInt, checkpointHeight: UInt? = nil)
    }
}
