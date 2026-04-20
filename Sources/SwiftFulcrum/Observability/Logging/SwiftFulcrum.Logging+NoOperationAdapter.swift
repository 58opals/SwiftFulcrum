// SwiftFulcrum.Logging+NoOperationAdapter.swift

import Foundation

extension SwiftFulcrum.Logging {
    public struct NoOperationAdapter: SwiftFulcrum.Logging.Adapter {
        public init() {}

        public func log(
            _ level: SwiftFulcrum.Logging.Level,
            _ message: @autoclosure () -> String,
            metadata: [String: String]?,
            file: String,
            function: String,
            line: UInt
        ) {}
    }
}
