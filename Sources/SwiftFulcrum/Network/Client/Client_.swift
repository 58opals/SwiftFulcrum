import Foundation
import Combine

protocol ClientWebSocketMessagable {
    func send(data: Data) async throws
    func send(string: String) async throws
}

protocol ClientEventSubscribable {
    var subscribers: Set<AnyCancellable> { get }
    
    func setupSubscriptions()
}

protocol ClientEventHandlable {
    func handleResponseData(_ data: Data)
}

protocol ClientJSONRPCMessagable {
    var jsonRPC: JSONRPC { get }
    
    func sendRequest(from method: Method) async throws -> UUID
    func sendRequest(_ request: Request) async throws
}
