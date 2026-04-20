// Response.Result.Mempool+GetInfo.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Mempool {
    public struct GetInfo: Decodable, Sendable {
        public let mempoolMinimumFee: Double?
        public let minimumRelayTransactionFee: Double?
        public let incrementalRelayFee: Double?
        public let unbroadcastCount: Int?
        public let isFullReplaceByFeeEnabled: Bool?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.GetInfo(from: decoder)
            self.mempoolMinimumFee = payloadModel.mempoolminfee?.value
            self.minimumRelayTransactionFee = payloadModel.minrelaytxfee?.value
            self.incrementalRelayFee = payloadModel.incrementalrelayfee?.value
            self.unbroadcastCount = payloadModel.unbroadcastcount
            self.isFullReplaceByFeeEnabled = payloadModel.isFullReplaceByFeeEnabled
        }
    }
}
