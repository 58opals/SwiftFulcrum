import Foundation

protocol JSONRPCRequestInitializable: Encodable, JSONRPCObjectable, JSONRPCObjectIdentifiable, JSONRPCObjectMethodable {
    var params: Encodable { get }
}

protocol JSONRPCRequestDataConvertible {
    var data: Data { get }
}
