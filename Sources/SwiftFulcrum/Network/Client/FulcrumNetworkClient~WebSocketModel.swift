// FulcrumNetworkClient~WebSocketModel.swift

import Foundation

extension FulcrumNetworkClient {
    func send(data: Data) async throws {
        try await transport.send(data: data)
    }
    
    func send(string: String) async throws {
        try await transport.send(string: string)
    }
}

extension FulcrumNetworkClient {
    func startReceiving() async {
        defer { receiveTask = nil }
        
        do {
            for try await message in await transport.makeMessageStream() {
                if let inflightCount = await handleMessage(message) { await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount) }
            }
        } catch {
            emitLog(.warning,
                    "client.receive.task_ended",
                    metadata: ["error": (error as NSError).localizedDescription])
            
            let info = await transport.closeInformation
            let closedError = await SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))
            
            let inflightCount = await self.router.failUnaries(with: closedError)
            await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        }
    }
}
