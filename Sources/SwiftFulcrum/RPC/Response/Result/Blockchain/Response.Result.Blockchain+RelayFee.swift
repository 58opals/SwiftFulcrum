// Response.Result.Blockchain+RelayFee.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain {
    public struct RelayFee: Decodable, Sendable {
        public let fee: Double

        public init(from decoder: Decoder) throws {
            let fee = try Double(from: decoder)
            guard fee.isFinite, fee >= 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid relay fee value")
            }
            self.fee = fee
        }
    }
}
