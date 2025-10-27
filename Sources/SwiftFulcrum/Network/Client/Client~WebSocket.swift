// Client~WebSocket.swift

import Foundation

extension Client {
    func send(data: Data) async throws {
        try await webSocket.send(data: data)
    }
    
    func send(string: String) async throws {
        try await webSocket.send(string: string)
    }
}

extension Client {
    func startReceiving() async {
        do {
            for try await message in await webSocket.makeMessageStream() {
                await handleMessage(message)
            }
        } catch {
            emitLog(.warning,
                    "client.receive.task_ended",
                    metadata: ["error": (error as NSError).localizedDescription])
            
            let closedError = await Fulcrum.Error.transport(
                .connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)
            )
            
            await self.router.failUnaries(with: closedError)
        }
    }
}
