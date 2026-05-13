// Response.Result.Mempool+Info.swift

import Foundation

extension SwiftFulcrum.Response.Mempool {
    public struct Info: Decodable, Sendable {
        public let mempoolMinimumFee: Double?
        public let minimumRelayTransactionFee: Double?
        public let incrementalRelayFee: Double?
        public let unbroadcastCount: Int?
        public let isFullReplaceByFeeEnabled: Bool?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.Info(from: decoder)
            self.mempoolMinimumFee = try Self.validateFee(payloadModel.mempoolminfee?.value, field: "mempoolminfee")
            self.minimumRelayTransactionFee = try Self.validateFee(payloadModel.minrelaytxfee?.value, field: "minrelaytxfee")
            self.incrementalRelayFee = try Self.validateFee(payloadModel.incrementalrelayfee?.value, field: "incrementalrelayfee")
            self.unbroadcastCount = try Self.validateCount(payloadModel.unbroadcastcount, field: "unbroadcastcount")
            self.isFullReplaceByFeeEnabled = payloadModel.isFullReplaceByFeeEnabled
        }

        private static func validateFee(_ value: Double?, field: String) throws -> Double? {
            guard let value else { return nil }
            guard value.isFinite, value >= 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid \(field): \(value)")
            }
            return value
        }

        private static func validateCount(_ value: Int?, field: String) throws -> Int? {
            guard let value else { return nil }
            guard value >= 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid \(field): \(value)")
            }
            return value
        }
    }
}
