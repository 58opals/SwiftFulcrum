// WebSocketConnection~Send.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func send(data: Data) async throws {
        let message = URLSessionWebSocketTask.Message.data(data)
        try await sendMessage(message, fields: OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "data", byteCount: data.count))
    }

    func send(string: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        try await sendMessage(message, fields: OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "string", byteCount: string.utf8.count))
    }

    private func sendMessage(
        _ message: URLSessionWebSocketTask.Message,
        fields: [OpalDiagnostics.Field]
    ) async throws {
        guard let task else {
            let error = SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketSendFailed,
                level: .info,
                fields: webSocketDiagnosticFields(fields + OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
            )
            throw error
        }

        let messageIdentifier = makeOutgoingMessageIdentifier()
        let eventFields = fields + [
            OpalDiagnostics.Field.swiftFulcrumField("message_id", messageIdentifier)
        ]

        OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
            event: .swiftFulcrumWebSocketSendBegin,
            level: .debug,
            fields: webSocketDiagnosticFields(eventFields)
        )
        do {
            try await task.send(message)
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketSendSucceeded,
                level: .debug,
                fields: webSocketDiagnosticFields(eventFields)
            )
        } catch {
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketSendFailed,
                level: .info,
                fields: webSocketDiagnosticFields(eventFields + OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
            )
            throw error
        }
    }
}
