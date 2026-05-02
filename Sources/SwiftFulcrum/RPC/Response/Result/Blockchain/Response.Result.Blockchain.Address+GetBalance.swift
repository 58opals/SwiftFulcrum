// Response.Blockchain.Address+GetBalance.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Address {
    public struct GetBalance: Decodable, Sendable {
        public let confirmed: UInt64
        public let unconfirmed: Int64

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetBalance(from: decoder)
            self.confirmed = payloadModel.confirmed
            self.unconfirmed = payloadModel.unconfirmed
        }
    }
}
