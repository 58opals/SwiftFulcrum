// Client.swift

import Foundation

public actor Client {
    let id: UUID
    let webSocket: WebSocket
    var jsonRPC: JSONRPC
    let router: Router
    let logger: Log.Handler
    
    var subscriptionMethods: [SubscriptionKey: Method]
    
    private var receiveTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    
    init(webSocket: WebSocket, metrics: MetricsCollectable? = nil, logger: Log.Handler? = nil) {
        self.id = .init()
        self.webSocket = webSocket
        self.jsonRPC = .init()
        self.router = .init()
        self.subscriptionMethods = .init()
        self.logger = logger ?? Log.NoOpHandler()
        if let metrics { Task { await self.webSocket.updateMetrics(metrics) } }
        Task { await self.webSocket.updateLogger(self.logger) }
    }
    
    func start() async throws {
        guard receiveTask == nil else { return }
        
        try await self.webSocket.connect()
        self.receiveTask = Task { await self.startReceiving() }
        self.lifecycleTask = Task { [weak self] in
            guard let self else { return }
            for await event in await self.webSocket.lifecycleEvents() {
                switch event {
                case .connected(let isReconnect) where isReconnect:
                    await self.emitLog(.info, "client.autoresubscribe.begin")
                    await self.resubscribeStoredMethods()
                    await self.emitLog(.info, "client.autoresubscribe.end", metadata: ["count": String(await self.subscriptionMethods.count)])
                default: break
                }
            }
        }
    }
    
    func stop() async {
        let closedError = await Fulcrum.Error.transport(
            .connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)
        )
        
        await self.router.failAll(with: closedError)
        
        receiveTask?.cancel()
        await receiveTask?.value
        receiveTask = nil
        lifecycleTask?.cancel()
        await lifecycleTask?.value
        lifecycleTask = nil
        
        await webSocket.disconnect(with: "Client.stop() called")
    }
    
    func reconnect(with url: URL? = nil) async throws {
        try await webSocket.reconnect(with: url)
        
        receiveTask?.cancel()
        await receiveTask?.value
        
        receiveTask = Task { await self.startReceiving() }
    }
}

extension Client {
    func emitLog(_ level: Log.Level,
                 _ message: @autoclosure () -> String,
                 metadata: [String: String] = [:],
                 file: String = #fileID, function: String = #function, line: UInt = #line) {
        var md = ["component": "Client", "client_id": id.uuidString]
        for (k, v) in metadata { md[k] = v }
        logger.log(level, message(), metadata: md, file: file, function: function, line: line)
    }
}
