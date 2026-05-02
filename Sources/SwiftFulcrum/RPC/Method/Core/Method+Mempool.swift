// Method+Mempool.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    enum Mempool: Sendable {
        case getInfo
        case getFeeHistogram
    }
}
