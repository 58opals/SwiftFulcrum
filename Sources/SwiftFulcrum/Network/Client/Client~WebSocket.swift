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
            await failAllPendingRequests(with: Fulcrum.Error.transport(.connectionClosed(webSocket.closeInformation.code, webSocket.closeInformation.reason)))
        }
    }
}
