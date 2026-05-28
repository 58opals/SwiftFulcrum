// FulcrumClientLifecycleValidator+ConnectionStateCollector.swift

import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    actor ConnectionStateCollector {
        private let targetCount: Int
        private var states: [SwiftFulcrum.Client.ConnectionState] = .init()

        init(targetCount: Int) {
            self.targetCount = targetCount
        }

        func record(_ state: SwiftFulcrum.Client.ConnectionState) -> Bool {
            states.append(state)
            return states.count >= targetCount
        }

        func makeSnapshot() -> [SwiftFulcrum.Client.ConnectionState] {
            states
        }
    }
}
