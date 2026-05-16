// WebSocketConnection~Send.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func send(data: Data) async throws {
        let message = URLSessionWebSocketTask.Message.data(data)
        try await sendMessage(message, fields: SwiftFulcrumDiagnostics.payloadFields(payloadType: "data", byteCount: data.count))
    }
    
    func send(string: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        try await sendMessage(message, fields: SwiftFulcrumDiagnostics.payloadFields(payloadType: "string", byteCount: string.utf8.count))
    }
    
    private func sendMessage(
        _ message: URLSessionWebSocketTask.Message,
        fields: [OpalDiagnostics.Field]
    ) async throws {
        guard let task else {
            let error = SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
            recordWebSocketEvent(
                SwiftFulcrumDiagnostics.Event.webSocketSendFailed,
                level: .error,
                fields: fields + SwiftFulcrumDiagnostics.errorFields(error)
            )
            throw error
        }
        
        let messageIdentifier = makeOutgoingMessageIdentifier()
        let eventFields = fields + [
            SwiftFulcrumDiagnostics.publicField("message_id", messageIdentifier)
        ]
        
        recordWebSocketEvent(SwiftFulcrumDiagnostics.Event.webSocketSendBegin, fields: eventFields)
        do {
            try await task.send(message)
            recordWebSocketEvent(SwiftFulcrumDiagnostics.Event.webSocketSendSucceeded, fields: eventFields)
        } catch {
            recordWebSocketEvent(
                SwiftFulcrumDiagnostics.Event.webSocketSendFailed,
                level: .error,
                fields: eventFields + SwiftFulcrumDiagnostics.errorFields(error)
            )
            throw error
        }
    }
}
