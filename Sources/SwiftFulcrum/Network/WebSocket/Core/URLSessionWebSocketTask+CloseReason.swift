// URLSessionWebSocketTask+CloseReason.swift

import Foundation

extension URLSessionWebSocketTask {
    var swiftFulcrumCloseReasonSummary: String? {
        Self.swiftFulcrumCloseReasonSummary(for: closeReason)
    }

    static func swiftFulcrumCloseReasonSummary(for closeReason: Data?) -> String? {
        closeReason.map { "WebSocket close reason redacted (\($0.count) bytes)." }
    }
}
