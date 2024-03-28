import Foundation

// MARK: - Object
protocol JSONRPCObjectable {
    var jsonrpc: String { get }
}

protocol JSONRPCObjectIdentifiable {
    var id: UUID { get }
}

protocol JSONRPCObjectMethodable {
    var method: String { get }
}
