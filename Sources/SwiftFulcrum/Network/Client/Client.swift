// Client.swift

import Foundation

actor Client {
    let id: UUID
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    let router: Router
    
    var regularResponseHandlers: [RegularResponseIdentifier: RegularResponseHandler]
    var subscriptionResponseHandlers: [SubscriptionResponseIdentifier: SubscriptionResponseHandler]
    
    private var receiveTask: Task<Void, Never>?
    
    init(webSocket: WebSocket) {
        self.id = .init()
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.router = .init()
        self.regularResponseHandlers = .init()
        self.subscriptionResponseHandlers = .init()
    }
    
    func start() async throws {
        guard receiveTask == nil else { return }
        
        try await self.webSocket.connect()
        self.receiveTask = Task { await self.startReceiving() }
    }
    
    func stop() async {
        let closedError = await Fulcrum.Error.transport(
            .connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)
        )
        
        self.failAllPendingRequests(with: closedError)
        await self.router.failAll(with: closedError)
        
        receiveTask?.cancel()
        await receiveTask?.value
        receiveTask = nil
        
        await webSocket.disconnect(with: "Client.stop() called")
    }
    
    func reconnect(with url: URL? = nil) async throws {
        try await webSocket.reconnect(with: url)
        
        receiveTask?.cancel()
        await receiveTask?.value
        
        receiveTask = Task { await self.startReceiving() }
    }
}
