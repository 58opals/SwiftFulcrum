import Foundation

public extension SwiftFulcrum.RPC {
    protocol ResponseProtocol: Decodable, Sendable {
        associatedtype JSONRPC: Decodable
        init(fromRPC jsonrpc: JSONRPC) throws
    }
}
