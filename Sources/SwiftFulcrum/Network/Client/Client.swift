// Client.swift

import Foundation

actor Client {
    let id: UUID
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    
    var regularResponseHandlers:      [RegularResponseIdentifier: RegularResponseHandler]
    var subscriptionResponseHandlers: [SubscriptionResponseIdentifier: SubscriptionResponseHandler]
    
    private var receivedTask: Task<Void, Never>?
    
    init(webSocket: WebSocket) {
        self.id = .init()
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.regularResponseHandlers = .init()
        self.subscriptionResponseHandlers = .init()
    }
    
    func start() async throws {
        try await self.webSocket.connect()
        
        self.receivedTask = Task { [weak self] in
            guard let self else { return }
            await self.observeMessages()
        }
    }
    
    func stop() async {
        receivedTask?.cancel()
        receivedTask = nil
        
        self.failAllPendingRequests(with: .connectionClosed)
        await webSocket.disconnect(with: "Client.stop() called")
    }
}
