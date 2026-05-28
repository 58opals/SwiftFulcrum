// Response.Result.Blockchain.ScriptHash+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let status: String?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe(from: decoder)
            switch payloadModel {
            case .scripthashAndStatus(let pair):
                guard pair.count == 2 else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected scripthash notification payload to contain [scripthash, status]; got \(pair.description)"
                    )
                }
                guard let first = pair.first, let scripthash = first else {
                    throw ResponseResultDecodeError.missingField("subscriptionIdentifier")
                }
                try SwiftFulcrum.Response.Blockchain.validateScriptHash(scripthash)
                self.subscriptionIdentifier = scripthash
                self.status = (pair.count > 1) ? pair[1] : nil
            case .status(let statusString):
                throw ResponseResultDecodeError.unexpectedFormat("Expected scripthash and status pair; got single status: \(statusString)")
            }
        }
    }
}
