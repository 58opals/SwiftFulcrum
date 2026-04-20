// JSONRPC.Result.Mempool+GetInfo.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool {
    struct GetInfo: Decodable, Sendable {
        let mempoolminfee: FlexibleNumber?
        let minrelaytxfee: FlexibleNumber?
        let incrementalrelayfee: FlexibleNumber?
        let unbroadcastcount: Int?
        let isFullReplaceByFeeEnabled: Bool?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKeyModel.self)
            let mempoolMinimumFeeKey = JSONRPCResponseDecodeModel.CodingKeyModel("mempoolminfee")
            let minimumRelayTransactionFeeKey = JSONRPCResponseDecodeModel.CodingKeyModel("minrelaytxfee")
            let incrementalRelayFeeKey = JSONRPCResponseDecodeModel.CodingKeyModel("incrementalrelayfee")
            let unbroadcastCountKey = JSONRPCResponseDecodeModel.CodingKeyModel("unbroadcastcount")
            let fullReplaceByFeeKey = JSONRPCResponseDecodeModel.CodingKeyModel("fullrbf")

            self.mempoolminfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: mempoolMinimumFeeKey)
            self.minrelaytxfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: minimumRelayTransactionFeeKey)
            self.incrementalrelayfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: incrementalRelayFeeKey)
            self.unbroadcastcount = try container.decodeIfPresent(Int.self, forKey: unbroadcastCountKey)
            self.isFullReplaceByFeeEnabled = try container.decodeIfPresent(Bool.self, forKey: fullReplaceByFeeKey)
        }
    }
}
