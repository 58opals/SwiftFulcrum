// Client.Error+Server.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public struct Server {
        public let id: UUID?
        public let code: Int
        public let message: String
        public let messageByteCount: Int

        init(id: UUID?, code: Int, message: String) {
            self.id = id
            self.code = code
            self.messageByteCount = message.utf8.count
            self.message = "JSON-RPC server error message redacted (\(message.utf8.count) UTF-8 bytes)"
        }
    }
}

extension SwiftFulcrum.Client.Error.Server: Swift.Error, Equatable, Sendable {}
