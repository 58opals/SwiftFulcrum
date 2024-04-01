import Foundation
import Combine

class Client {
    let webSocket: NetworkConnectable & WebSocketReconnectable & WebSocketMessagable & WebSocketEventPublishable
    
    init(webSocket: WebSocket,
         storage: Storage = .init()) {
        self.webSocket = webSocket
        self.webSocket.connect()
        
        self.jsonRPC = JSONRPC(storage: storage)
        self.setupWebSocketSubscriptions()
        self.setupResultBoxSubscriptions()
    }
    
    // MARK: ClientJSONRPCMessagable
    var jsonRPC: JSONRPC
    
    // MARK: ClientEventSubscribable
    var subscribers = Set<AnyCancellable>()
    
    // MARK: ClientResultBoxEventSubscribable
    var onResultIDReceived: ((UUID) -> Void)?
}
