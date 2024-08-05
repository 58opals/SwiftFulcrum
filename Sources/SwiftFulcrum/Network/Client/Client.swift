import Foundation
import Combine

final class Client {
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    var subscribers = Set<AnyCancellable>()
    var externalDataHandler: ((Data) throws -> Void)?
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
        self.webSocket.connect()
        
        self.jsonRPC = JSONRPC()
        self.setupWebSocketSubscriptions()
    }
}
