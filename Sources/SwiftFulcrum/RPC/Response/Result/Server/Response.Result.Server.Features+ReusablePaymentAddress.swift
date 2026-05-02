// Response.Server.Features+ReusablePaymentAddress.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    public struct ReusablePaymentAddress: Decodable, Sendable {
        public let historyBlockLimit: Int?
        public let maximumHistoryItems: Int?
        public let indexedPrefixBits: Int?
        public let minimumPrefixBits: Int?
        public let startingHeight: Int?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.ReusablePaymentAddress) {
            self.historyBlockLimit = payloadModel.history_block_limit
            self.maximumHistoryItems = payloadModel.max_history
            self.indexedPrefixBits = payloadModel.prefix_bits
            self.minimumPrefixBits = payloadModel.prefix_bits_min
            self.startingHeight = payloadModel.starting_height
        }
    }
}
