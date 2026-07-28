// OpalDiagnostics.Field+SwiftFulcrumPayload.swift

import Foundation
import OpalDiagnostics

extension OpalDiagnostics.Field {
    static func swiftFulcrumPayloadFields(payloadType: String, byteCount: Int) -> [Self] {
        [
            swiftFulcrumField("payload_type", payloadType),
            swiftFulcrumField("byte_count", byteCount)
        ]
    }

    static func swiftFulcrumPayloadFields(for message: URLSessionWebSocketTask.Message) -> [Self] {
        switch message {
        case .data(let data):
            swiftFulcrumPayloadFields(payloadType: "data", byteCount: data.count)
        case .string(let string):
            swiftFulcrumPayloadFields(payloadType: "string", byteCount: string.utf8.count)
        @unknown default:
            swiftFulcrumPayloadFields(payloadType: "unknown", byteCount: 0)
        }
    }
}
