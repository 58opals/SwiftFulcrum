// Transaction+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let transactionHash: String
        public let height: UInt?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.Subscribe(from: decoder)
            switch payloadModel {
            case .transactionHashAndHeight(let pairs):
                var hashValue: String?
                var heightValue: UInt?
                var hasHeight = false

                for pair in pairs {
                    switch pair {
                    case .transactionHash(let transactionHash):
                        guard hashValue == nil else { throw ResponseResultDecodeError.unexpectedFormat("Duplicate transaction hash in notification payload") }
                        hashValue = transactionHash
                    case .height(let height):
                        guard !hasHeight else { throw ResponseResultDecodeError.unexpectedFormat("Duplicate height in notification payload") }
                        heightValue = height
                        hasHeight = true
                    }
                }

                guard let transactionHash = hashValue else { throw ResponseResultDecodeError.missingField("transactionHash") }
                guard hasHeight else { throw ResponseResultDecodeError.missingField("height") }

                self.subscriptionIdentifier = transactionHash
                self.transactionHash = transactionHash
                self.height = heightValue
            case .height(let height):
                throw ResponseResultDecodeError.unexpectedFormat("Expected [txid, height] for Transaction.Subscribe; got height only: \(String(describing: height))")
            }
        }
    }
}
