// Transaction+Height.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct Height: Decodable, Sendable {
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

extension SwiftFulcrum.Response.Blockchain.Transaction.Height: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { .init(height: nil) }
}
