// Response.Blockchain+EstimateFee.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain {
    public struct EstimateFee: Decodable, Sendable {
        public let fee: Double

        public init(from decoder: Decoder) throws {
            self.fee = try Double(from: decoder)
        }
    }
}
