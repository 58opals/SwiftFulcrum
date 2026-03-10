// Transaction+Subscribe.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct Subscribe: Decodable, Sendable {
        public let height: UInt

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
