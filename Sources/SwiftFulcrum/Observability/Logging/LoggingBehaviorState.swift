// LoggingBehaviorState.swift

import Foundation

enum LoggingBehaviorState {
    @TaskLocal static var behavior: SwiftFulcrum.Logging.Behavior = .normal
}
