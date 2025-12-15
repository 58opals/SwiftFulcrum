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
                await handleMessage(message)
            }
        } catch {
            emitLog(.warning,
                    "client.receive.task_ended",
                    metadata: ["error": (error as NSError).localizedDescription])
            
            let info = await transport.closeInformation
            let closedError = await Fulcrum.Error.transport(.connectionClosed(info.code, info.reason))
            
            await self.router.failUnaries(with: closedError)
        }
    }
}
