// Transaction+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let transactionHash: String
        public let height: UInt?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Subscribe(from: decoder)
            switch payloadModel {
            case .transactionHashAndHeight(let pairs):
                guard pairs.count == 2 else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected transaction notification payload to contain [txid, height]; got \(pairs.count) values"
                    )
                }
                guard case .transactionHash(let transactionHash) = pairs[0] else {
                    throw ResponseResultDecodeError.unexpectedFormat("Expected transaction hash as first notification value")
                }
                guard case .height(let heightValue) = pairs[1] else {
                    throw ResponseResultDecodeError.unexpectedFormat("Expected height as second notification value")
                }
                try SwiftFulcrum.Response.Blockchain.validateTransactionHash(transactionHash)

                self.subscriptionIdentifier = transactionHash
                self.transactionHash = transactionHash
                self.height = heightValue
            case .height(let height):
                throw ResponseResultDecodeError.unexpectedFormat("Expected [txid, height] for Transaction.Subscribe; got height only: \(String(describing: height))")
            }
        }
    }
}
