import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    actor ConnectionStateCollectorModel {
        private let targetCount: Int
        private var states: [FulcrumClient.ConnectionState] = .init()

        init(targetCount: Int) {
            self.targetCount = targetCount
        }

        func record(_ state: FulcrumClient.ConnectionState) -> Bool {
            states.append(state)
            return states.count >= targetCount
        }

        func snapshot() -> [FulcrumClient.ConnectionState] {
            states
        }
    }
}
