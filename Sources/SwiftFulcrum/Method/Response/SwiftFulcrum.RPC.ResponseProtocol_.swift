// JSONRPCResponse_.swift

import Foundation

public extension SwiftFulcrum.RPC {
    protocol ResponseProtocol: Decodable, Sendable {
        associatedtype JSONRPCModel: Decodable
        init(fromRPC jsonrpc: JSONRPCModel) throws
    }
}
