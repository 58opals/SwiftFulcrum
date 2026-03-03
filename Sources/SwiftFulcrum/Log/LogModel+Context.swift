// LogModel+Context.swift

import Foundation

extension LogModel {
    enum Context {
        @TaskLocal static var behavior: Behavior = .normal
    }
}
