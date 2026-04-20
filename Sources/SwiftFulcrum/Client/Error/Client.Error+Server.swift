// Client.Error+Server.swift

import Foundation

extension SwiftFulcrum.Client.Error {
    public struct Server {
        public let id: UUID?
        public let code: Int
        public let message: String
    }
}

extension SwiftFulcrum.Client.Error.Server: Swift.Error, Equatable, Sendable {}
