// OpalDiagnostics.Field+SwiftFulcrum.swift

import Foundation
public import OpalDiagnostics

public extension OpalDiagnostics.Field {
    static let swiftFulcrumErrorCodeName = "error_code"
}

extension OpalDiagnostics.Field {
    static func swiftFulcrumField(_ name: String, _ value: String) -> Self {
        Self(name: name, publicValue: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: Int) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: UInt64) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: Bool) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumField(_ name: String, _ value: UUID) -> Self {
        Self(name: name, value: value)
    }

    static func swiftFulcrumPrivateField(_ name: String, _ value: String) -> Self {
        Self(name: name, value: value, privacy: .private)
    }

    static func swiftFulcrumMethodPath(_ methodPath: String) -> Self {
        swiftFulcrumField("method_path", methodPath)
    }

    static func swiftFulcrumEndpointURL(_ url: URL) -> Self {
        swiftFulcrumPrivateField("endpoint_url", url.absoluteString)
    }

    static func swiftFulcrumNetwork(_ network: SwiftFulcrum.Client.Configuration.Network) -> Self {
        swiftFulcrumField("network", network.resourceName)
    }

    static func swiftFulcrumErrorCode(_ errorCode: String) -> Self {
        swiftFulcrumField(swiftFulcrumErrorCodeName, errorCode)
    }

    static func swiftFulcrumErrorFields(_ error: Swift.Error) -> [Self] {
        [
            swiftFulcrumErrorCode(swiftFulcrumErrorCode(for: error)),
            swiftFulcrumField("error_type", String(reflecting: Swift.type(of: error))),
            swiftFulcrumPrivateField("error_message", (error as NSError).localizedDescription)
        ]
    }

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
