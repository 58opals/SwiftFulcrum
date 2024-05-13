import Foundation

protocol FulcrumResponseResultInitializable: Decodable {
    associatedtype JSONRPC: Decodable
    init(jsonrpcResult: JSONRPC)
}

public protocol FulcrumResponseResultTypable {
    associatedtype ResultType
    var resultType: ResultType.Type { get }
}

protocol FulcrumRegularResponseResultInitializable: FulcrumResponseResultInitializable {}

protocol FulcrumSubscriptionResponseResultInitializable: FulcrumResponseResultInitializable {
    var subscriptionIdentifier: String { get }
}
