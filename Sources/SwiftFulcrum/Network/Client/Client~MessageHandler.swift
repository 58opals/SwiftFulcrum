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
            else { print("Failed to convert string message to Data.") }
        @unknown default:
            print("Unknown message type")
        }
    }
}
