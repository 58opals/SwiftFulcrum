// Response.Result.Blockchain+RelayFee.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct RelayFee: Decodable, Sendable {
        public let fee: Double

        public init(from decoder: Decoder) throws {
            self.fee = try Double(from: decoder)
        }
    }
}
