// SwiftFulcrum.Logging+Adapter.swift

import Foundation

extension SwiftFulcrum.Logging {
    public protocol Adapter: Sendable {
        func log(
            _ level: Level,
            _ message: @autoclosure () -> String,
            metadata: [String: String]?,
            file: String,
            function: String,
            line: UInt
        )
    }
}

extension SwiftFulcrum.Logging.Adapter {
    func trace(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.trace, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func debug(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func logInfo(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func notice(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.notice, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func logWarning(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func logError(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }

    func logCritical(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.critical, message(), metadata: metadata, file: file, function: function, line: line)
    }
}
