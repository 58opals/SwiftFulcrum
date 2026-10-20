// WebSocketConnection~Send.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func send(data: Data, sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization? = nil) async throws {
        let message = URLSessionWebSocketTask.Message.data(data)
        try await sendMessage(message, fields: OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "data", byteCount: data.count),
            sendAuthorization: sendAuthorization)
    }

    func send(string: String, sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization? = nil) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        try await sendMessage(message, fields: OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "string", byteCount: string.utf8.count),
            sendAuthorization: sendAuthorization)
    }

    private func sendMessage(
        _ message: URLSessionWebSocketTask.Message,
        fields: [OpalDiagnostics.Field],
        sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization?
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
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
                do {
                    try Task.checkCancellation()
                    try sendAuthorization?.validate()
                    task.send(message) { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
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
