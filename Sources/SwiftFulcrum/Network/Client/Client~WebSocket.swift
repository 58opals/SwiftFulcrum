// Client~WebSocket.swift

import Foundation

extension Client {
    func send(data: Data) async throws {
        try await transport.send(data: data)
    }
    
    func send(string: String) async throws {
        try await transport.send(string: string)
    }
}

extension Client {
    func startReceiving() async {
        do {
            for try await message in await transport.makeMessageStream() {
                if let inflightCount = await handleMessage(message) { await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount) }
            }
        } catch {
            emitLog(.warning,
                    "client.receive.task_ended",
                    metadata: ["error": (error as NSError).localizedDescription])
            
            let info = await transport.closeInformation
            let closedError = await Fulcrum.Error.transport(.connectionClosed(info.code, info.reason))
            
            let inflightCount = await self.router.failUnaries(with: closedError)
            await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        }
    }
}
