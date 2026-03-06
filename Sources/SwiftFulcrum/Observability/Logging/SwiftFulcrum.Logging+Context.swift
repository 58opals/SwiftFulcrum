// SwiftFulcrum.Logging+Context.swift

import Foundation

extension SwiftFulcrum.Logging {
    enum Context {
        @TaskLocal static var behavior: Behavior = .normal
    }
}
