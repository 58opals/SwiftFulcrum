// Transaction+GetHeight.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct GetHeight: Decodable, Sendable {
        public let height: UInt?

        init(height: UInt?) {
            self.height = height
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.height = container.decodeNil() ? nil : try container.decode(UInt.self)
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.GetHeight: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(height: nil) }
}
