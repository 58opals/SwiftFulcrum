// Transaction+GetHeight.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct GetHeight: Decodable, Sendable {
        public let height: UInt

        public init(from decoder: Decoder) throws {
            self.height = try UInt(from: decoder)
        }
    }
}
