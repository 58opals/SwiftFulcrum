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
            for try await message in await webSocket.messages() {
                await handleMessage(message)
            }
        } catch {
            print("Receive task ended: \(error.localizedDescription)")
            
            let closedError = await Fulcrum.Error.transport(
                .connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)
            )
            
            self.failAllPendingRequests(with: closedError)
            await self.router.failAll(with: closedError)
        }
    }
}
