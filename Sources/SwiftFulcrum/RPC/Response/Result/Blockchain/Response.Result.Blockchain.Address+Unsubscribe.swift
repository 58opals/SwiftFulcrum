// Response.Result.Blockchain.Address+Unsubscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct Unsubscribe: Decodable, Sendable {
        public let isSuccess: Bool

        public init(from decoder: Decoder) throws {
            self.isSuccess = try Bool(from: decoder)
        }
    }
}
