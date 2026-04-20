// Response.Result.Blockchain.Address+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let status: String?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe(from: decoder)
            switch payloadModel {
            case .addressAndStatus(let pair):
                guard (1 ... 2).contains(pair.count) else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected address notification payload to contain [address] or [address, status]; got \(pair.description)"
                    )
                }
                guard let first = pair.first, let address = first else {
                    throw ResponseResultDecodeError.missingField("subscriptionIdentifier")
                }
                self.subscriptionIdentifier = address
                self.status = (pair.count > 1) ? pair[1] : nil
            case .status(let statusString):
                throw ResponseResultDecodeError.unexpectedFormat("Expected address and status pair; got single status: \(statusString)")
            }
        }
    }
}
