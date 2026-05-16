// WebSocketConnection~Diagnostics.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func recordWebSocketEvent(
        _ event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category = SwiftFulcrumDiagnostics.Category.webSocket,
        level: OpalDiagnostics.Level = .debug,
        traceID: OpalDiagnostics.TraceID? = nil,
        fields: [OpalDiagnostics.Field] = []
    ) {
        SwiftFulcrumDiagnostics.record(
            event,
            category: category,
            level: level,
            traceID: traceID,
            fields: [
                SwiftFulcrumDiagnostics.endpointField(url),
                SwiftFulcrumDiagnostics.networkField(network)
            ] + fields
        )
    }
}
