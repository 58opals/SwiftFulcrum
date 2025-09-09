// Client~MessageHandler.swift

import Foundation

extension Client {
    func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .data(let data):
            await router.handle(raw: data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                await router.handle(raw: data)
            }
            else { emitLog(.warning, "ws.message.string.decode_failed") }
        @unknown default:
            emitLog(.warning, "ws.message.unknown_type")
        }
    }
}
