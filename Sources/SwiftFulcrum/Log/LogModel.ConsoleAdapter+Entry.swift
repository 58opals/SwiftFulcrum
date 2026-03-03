// LogModel.ConsoleAdapter+Entry.swift

import Foundation

extension LogModel.ConsoleAdapter {
    struct Entry: Sendable {
        let level: LogModel.Level
        let timestamp: String
        let message: String
        let metadata: [String: String]?
        let file: String
        let function: String
        let line: UInt
    }
}
