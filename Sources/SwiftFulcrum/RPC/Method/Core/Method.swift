// Method.swift

import Foundation

extension SwiftFulcrum.RPC {
    enum Method: Sendable {
        case server(Server)
        case blockchain(Blockchain)
        case mempool(Mempool)
    }
}
