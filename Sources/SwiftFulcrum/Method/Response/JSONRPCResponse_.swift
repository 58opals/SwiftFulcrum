// JSONRPCResponse_.swift

import Foundation

public protocol JSONRPCResponse: Decodable, Sendable {
    associatedtype JSONRPCModel: Decodable
    init(fromRPC jsonrpc: JSONRPCModel) throws
}
