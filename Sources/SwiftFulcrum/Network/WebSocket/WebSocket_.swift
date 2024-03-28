import Foundation
import Combine

protocol WebSocketReconnectable {
    var reconnector: WebSocket.Reconnector { get }
    
    func reconnect() async throws
}

protocol WebSocketMessagable {
    func send(data: Data) async throws
    func send(string: String) async throws
    func receive() async throws -> URLSessionWebSocketTask.Message
    func listen() async throws
}

protocol WebSocketEventPublishable {
    var receivedData: PassthroughSubject<Data, Never> { get }
    var receivedString: PassthroughSubject<String, Never> { get }
    
    func publish(message: URLSessionWebSocketTask.Message) throws
}
