// WebSocketReconnectorValidator+SleepCountActor.swift

import Foundation

extension WebSocketReconnectorValidator {
    actor SleepCountActor {
        private var value = 0

        func increment() {
            value += 1
        }

        func reset() {
            value = 0
        }

        func read() -> Int { value }
    }
}
