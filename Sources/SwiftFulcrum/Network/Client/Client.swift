// Client.swift

import Foundation

actor Client {
    let id: UUID
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    
    var regularResponseHandlers:      [RegularResponseIdentifier: RegularResponseHandler]
    var subscriptionResponseHandlers: [SubscriptionResponseIdentifier: SubscriptionResponseHandler]
    
    init(webSocket: WebSocket) {
        self.id = .init()
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.regularResponseHandlers = .init()
        self.subscriptionResponseHandlers = .init()
    }
    
    func start() async throws {
        try await self.webSocket.connect()
        Task { await self.startReceiving() }
    }
    
    func stop() async {
        self.failAllPendingRequests(with: .connectionClosed)
        await webSocket.disconnect(with: "Client.stop() called")
    }
}
