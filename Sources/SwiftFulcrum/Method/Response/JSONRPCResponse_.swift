// JSONRPCResponse_.swift

import Foundation

@available(*, deprecated, message: "Use SwiftFulcrum.RPC.ResponseProtocol instead.")
public protocol JSONRPCResponse: Decodable, Sendable {
    associatedtype JSONRPCModel: Decodable
    init(fromRPC jsonrpc: JSONRPCModel) throws
}
