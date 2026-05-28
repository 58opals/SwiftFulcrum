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
            try SwiftFulcrum.Response.Server.Features.validateNonNegative(payloadModel.history_block_limit, field: "rpa history_block_limit")
            try SwiftFulcrum.Response.Server.Features.validateNonNegative(payloadModel.max_history, field: "rpa max_history")
            try SwiftFulcrum.Response.Server.Features.validateNonNegative(payloadModel.prefix_bits, field: "rpa prefix_bits")
            try SwiftFulcrum.Response.Server.Features.validateNonNegative(payloadModel.prefix_bits_min, field: "rpa prefix_bits_min")
            try SwiftFulcrum.Response.Server.Features.validateNonNegative(payloadModel.starting_height, field: "rpa starting_height")
            try Self.validatePrefixBitRange(indexed: payloadModel.prefix_bits, minimum: payloadModel.prefix_bits_min)

            self.historyBlockLimit = payloadModel.history_block_limit
            self.maximumHistoryItems = payloadModel.max_history
            self.indexedPrefixBits = payloadModel.prefix_bits
            self.minimumPrefixBits = payloadModel.prefix_bits_min
            self.startingHeight = payloadModel.starting_height
        }

        private static func validatePrefixBitRange(indexed: Int?, minimum: Int?) throws {
            guard let indexed, let minimum else { return }
            guard minimum <= indexed else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Invalid server.features rpa prefix bit range: \(minimum) exceeds \(indexed)"
                )
            }
        }
    }
}
