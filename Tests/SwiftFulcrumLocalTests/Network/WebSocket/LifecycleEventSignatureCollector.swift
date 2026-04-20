// LifecycleEventSignatureCollector.swift

@testable import SwiftFulcrum

actor LifecycleEventSignatureCollector {
    private let targetCount: Int
    private var values: [String] = .init()

    init(targetCount: Int) {
        self.targetCount = targetCount
    }

    func record(_ event: WebSocketConnection.Lifecycle.Event) -> Bool {
        values.append(signature(for: event))
        return values.count >= targetCount
    }

    func snapshot() -> [String] {
        values
    }

    private func signature(for event: WebSocketConnection.Lifecycle.Event) -> String {
        switch event {
        case .connected(let isReconnect):
            return "connected:\(isReconnect)"
        case .disconnected(let code, let reason):
            return "disconnected:\(code.rawValue):\(reason ?? "nil")"
        }
    }
}
