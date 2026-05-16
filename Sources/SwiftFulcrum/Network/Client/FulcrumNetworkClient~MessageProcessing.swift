// FulcrumNetworkClient~MessageProcessing.swift

import Foundation

extension FulcrumNetworkClient {
    func handleMessage(_ message: URLSessionWebSocketTask.Message) async -> Int? {
        switch message {
        case .data(let data):
            return await router.handle(raw: data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                return await router.handle(raw: data)
            }
            else {
                recordClientEvent(
                    SwiftFulcrumDiagnostics.Event.webSocketReceiveFailed,
                    category: SwiftFulcrumDiagnostics.Category.webSocket,
                    level: .error,
                    fields: SwiftFulcrumDiagnostics.payloadFields(payloadType: "string", byteCount: string.utf8.count)
                )
            }
        @unknown default:
            recordClientEvent(
                SwiftFulcrumDiagnostics.Event.webSocketReceiveFailed,
                category: SwiftFulcrumDiagnostics.Category.webSocket,
                level: .error,
                fields: SwiftFulcrumDiagnostics.payloadFields(payloadType: "unknown", byteCount: 0)
            )
        }
        
        return nil
    }
}
