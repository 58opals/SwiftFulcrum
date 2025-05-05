// Client.swift

import Foundation

actor Client {
    let id:        UUID
    let webSocket: WebSocket
    var jsonRPC:   JSONRPC
    let router:    Router
    
    var regularResponseHandlers:      [RegularResponseIdentifier: RegularResponseHandler]
    var subscriptionResponseHandlers: [SubscriptionResponseIdentifier: SubscriptionResponseHandler]
    
    init(webSocket: WebSocket) {
        self.id = .init()
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.router = .init()
        self.regularResponseHandlers = .init()
        self.subscriptionResponseHandlers = .init()
    }
    
    func start() async throws {
        try await self.webSocket.connect()
        Task { await self.startReceiving() }
    }
    
    func stop() async {
        await self.failAllPendingRequests(with: Fulcrum.Error.transport(.connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)))
        await webSocket.disconnect(with: "Client.stop() called")
    }
}
