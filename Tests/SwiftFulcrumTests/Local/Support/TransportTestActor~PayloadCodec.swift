import Foundation

extension TransportTestActor {
    static func decodeJSONObject(
        from message: URLSessionWebSocketTask.Message
    ) throws -> [String: Any] {
        guard
            let data = message.dataPayload,
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw NSError(domain: "TransportTestActor", code: 0)
        }
        return jsonObject
    }

    static func encodeResponsePayload(
        identifier: String,
        result: Any
    ) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "jsonrpc": "2.0",
                "id": identifier,
                "result": result
            ]
        )
    }

    static func encodeErrorPayload(
        identifier: String,
        code: Int,
        message: String
    ) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "jsonrpc": "2.0",
                "id": identifier,
                "error": [
                    "code": code,
                    "message": message
                ]
            ]
        )
    }

    static func encodeEmptyPayload(identifier: String) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "jsonrpc": "2.0",
                "id": identifier
            ]
        )
    }

    static func encodeSubscriptionNotification(
        method: String,
        parameters: [Any]
    ) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "jsonrpc": "2.0",
                "method": method,
                "params": parameters
            ]
        )
    }
}
