import Foundation

actor Client {
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    var regularResponseHandlers: [UUID: (Data) throws -> Void]
    var subscriptionResponseHandlers: [String: (Data) throws -> Void]
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.regularResponseHandlers = .init()
        self.subscriptionResponseHandlers = .init()
    }
    
    func start() async throws {
        try await self.webSocket.connect()
        
        Task {
            await self.observeMessages()
        }
    }
}
