// Method.Blockchain+Headers.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain {
    public enum Headers: Sendable {
        case getTip
        case subscribe
        case unsubscribe
    }
}
