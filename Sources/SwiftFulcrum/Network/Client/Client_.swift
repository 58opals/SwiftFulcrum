import Foundation
import Combine

protocol ClientWebSocketMessagable {
    func send(data: Data) async throws
    func send(string: String) async throws
}

protocol ClientEventSubscribable {
    var subscribers: Set<AnyCancellable> { get }
}

protocol ClientWebSocketEventSubscribable: ClientEventSubscribable {
    func setupWebSocketSubscriptions()
}

protocol ClientWebSocketEventHandlable {
    func handleResponseData(_ data: Data)
}

protocol ClientResultBoxEventSubscribable: ClientEventSubscribable {
    var onResultIDReceived: ((UUID) -> Void)? { get }
    
    func setupResultBoxSubscriptions()
}

protocol ClientResultBoxEventHandlable {
    func handleResultID(_ id: UUID)
}

protocol ClientJSONRPCMessagable {
    var jsonRPC: JSONRPC { get }
    
    func sendRequest(from method: Method) async throws -> UUID
    func sendRequest(_ request: Request) async throws
}
