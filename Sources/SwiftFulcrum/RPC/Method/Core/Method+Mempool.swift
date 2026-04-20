// Method+Mempool.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    public enum Mempool: Sendable {
        case getInfo
        case getFeeHistogram
    }
}
