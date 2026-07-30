// Method.Blockchain+RPA.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    enum RPA: Sendable {
        case getHistory(prefix: String, fromHeight: UInt, toHeight: UInt?)
        case getMempool(prefix: String)
    }
}
