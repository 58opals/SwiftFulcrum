// ClientDiagnosticsTransportState.swift

import Foundation

struct ClientDiagnosticsTransportState: Sendable {
    let reconnectAttempts: Int
    let reconnectSuccesses: Int
}
