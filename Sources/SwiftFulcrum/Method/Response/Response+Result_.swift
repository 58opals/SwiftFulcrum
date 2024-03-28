import Foundation

protocol FulcrumResponseResultInitializable: Decodable {
    associatedtype JSONRPC: Decodable
    init(jsonrpcResult: JSONRPC)
}

protocol FulcrumRegularResponseResultInitializable: FulcrumResponseResultInitializable {}

protocol FulcrumSubscriptionResponseResultInitializable: FulcrumResponseResultInitializable {
    var subscriptionIdentifier: String { get }
}
