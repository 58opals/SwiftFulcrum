// Response.Result.Server.Features+ReusablePaymentAddress.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    public struct ReusablePaymentAddress: Decodable, Sendable {
        public let historyBlockLimit: Int?
        public let maximumHistoryItems: Int?
        public let indexedPrefixBits: Int?
        public let minimumPrefixBits: Int?
        public let startingHeight: Int?

        init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.ReusablePaymentAddress) throws {
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.history_block_limit, field: "rpa history_block_limit", range: 0 ... Int.max)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.max_history, field: "rpa max_history", range: 0 ... Int.max)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.prefix_bits, field: "rpa prefix_bits", range: 0 ... Int.max)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.prefix_bits_min, field: "rpa prefix_bits_min", range: 0 ... Int.max)
            try SwiftFulcrum.Response.Server.Features.validate(payloadModel.starting_height, field: "rpa starting_height", range: 0 ... Int.max)

            self.historyBlockLimit = payloadModel.history_block_limit
            self.maximumHistoryItems = payloadModel.max_history
            self.indexedPrefixBits = payloadModel.prefix_bits
            self.minimumPrefixBits = payloadModel.prefix_bits_min
            self.startingHeight = payloadModel.starting_height
        }
    }
}
