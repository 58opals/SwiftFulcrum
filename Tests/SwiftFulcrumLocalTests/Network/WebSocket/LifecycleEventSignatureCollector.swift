// LifecycleEventSignatureCollector.swift

@testable import SwiftFulcrum

actor LifecycleEventSignatureCollector {
    private let targetCount: Int
    private var values: [String] = .init()

    init(targetCount: Int) {
        self.targetCount = targetCount
    }

    func record(_ event: WebSocketConnection.Lifecycle.Event) -> Bool {
        values.append(makeSignature(for: event))
        return values.count >= targetCount
    }

    func makeSnapshot() -> [String] {
        values
    }

    private func makeSignature(for event: WebSocketConnection.Lifecycle.Event) -> String {
        switch event {
        case .connected(let isReconnect):
            return "connected:\(isReconnect)"
        case .disconnected(let code, let reason):
            return "disconnected:\(code.rawValue):\(reason ?? "nil")"
        }
    }
}
