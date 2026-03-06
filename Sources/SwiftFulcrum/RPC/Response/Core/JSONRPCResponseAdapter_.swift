// JSONRPCResponseAdapter_.swift

import Foundation

public extension SwiftFulcrum.RPC {
    protocol JSONRPCResponseAdapter: Decodable, Sendable {
        associatedtype JSONRPC: Decodable
        init(fromRPC jsonrpc: JSONRPC) throws
    }
}
