// LoggingConsoleEntry.swift

import Foundation

struct LoggingConsoleEntry: Sendable {
    let level: SwiftFulcrum.Logging.Level
    let timestamp: String
    let message: String
    let metadata: [String: String]?
    let file: String
    let function: String
    let line: UInt
}
