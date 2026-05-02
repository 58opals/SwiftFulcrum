// Response.Blockchain.Headers+SubscribeNotification.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers {
    public struct SubscribeNotification: Decodable, Sendable {
        public let subscriptionIdentifier: String
        public let blocks: [Block]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Subscribe(from: decoder)
            self.subscriptionIdentifier = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path

            switch payloadModel {
            case .newHeader(let list):
                guard !list.isEmpty else {
                    throw ResponseResultDecodeError.missingField("header list empty")
                }
                self.blocks = list.map { Block(height: $0.height, hex: $0.hex) }
            case .topHeader(let tip):
                self.blocks = [Block(height: tip.height, hex: tip.hex)]
            }
        }
    }
}
