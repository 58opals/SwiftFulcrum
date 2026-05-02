// Transaction+Subscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct Subscribe: Decodable, Sendable {
        public let height: UInt?

        init(height: UInt?) {
            self.height = height
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Subscribe(from: decoder)
            switch payloadModel {
            case .height(let height):
                self.height = height
            case .transactionHashAndHeight(let pairs):
                throw ResponseResultDecodeError.unexpectedFormat("Expected a height uint; got transaction hash and height array for Transaction.Subscribe: \(pairs.description)")
            }
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.Transaction.Subscribe: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(height: nil) }
}
