import Foundation
import Combine

final class Client {
    let webSocket: NetworkConnectable & WebSocketReconnectable & WebSocketMessagable & WebSocketEventPublishable
    
    init(webSocket: WebSocket,
         storage: Storage) {
        self.webSocket = webSocket
        self.webSocket.connect()
        
        self.jsonRPC = JSONRPC(storage: storage)
        self.setupWebSocketSubscriptions()
    }
    
    // MARK: ClientJSONRPCMessagable
    var jsonRPC: JSONRPC
    
    // MARK: ClientEventSubscribable
    var subscribers = Set<AnyCancellable>()
}
