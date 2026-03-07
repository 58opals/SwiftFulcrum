// JSONRPCResponseAdapter_.swift

import Foundation

extension SwiftFulcrum.RPC {
    public protocol JSONRPCResponseAdapter: Decodable, Sendable {
        associatedtype JSONRPC: Decodable
        init(fromRPC jsonrpc: JSONRPC) throws
    }
}
