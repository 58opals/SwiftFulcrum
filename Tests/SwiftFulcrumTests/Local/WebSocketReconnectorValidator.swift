import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct WebSocketReconnectorValidator {
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
