// FulcrumNetworkClient~MessageProcessing.swift

import Foundation
import OpalDiagnostics

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
                OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                    event: .swiftFulcrumWebSocketReceiveFailed,
                    level: .info,
                    fields: makeClientDiagnosticFields(
                        OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "string", byteCount: string.utf8.count)
                    )
                )
            }
        @unknown default:
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketReceiveFailed,
                level: .info,
                fields: makeClientDiagnosticFields(
                    OpalDiagnostics.Field.swiftFulcrumPayloadFields(payloadType: "unknown", byteCount: 0)
                )
            )
        }

        return nil
    }
}
