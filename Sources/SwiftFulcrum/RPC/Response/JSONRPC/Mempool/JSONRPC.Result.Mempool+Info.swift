// JSONRPC.Result.Mempool+Info.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool {
    struct Info: Decodable, Sendable {
        let mempoolminfee: FlexibleNumber?
        let minrelaytxfee: FlexibleNumber?
        let incrementalrelayfee: FlexibleNumber?
        let unbroadcastcount: Int?
        let isFullReplaceByFeeEnabled: Bool?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKey.self)
            let mempoolMinimumFeeKey = JSONRPCResponseDecodeModel.CodingKey("mempoolminfee")
            let minimumRelayTransactionFeeKey = JSONRPCResponseDecodeModel.CodingKey("minrelaytxfee")
            let incrementalRelayFeeKey = JSONRPCResponseDecodeModel.CodingKey("incrementalrelayfee")
            let unbroadcastCountKey = JSONRPCResponseDecodeModel.CodingKey("unbroadcastcount")
            let fullReplaceByFeeKey = JSONRPCResponseDecodeModel.CodingKey("fullrbf")

            self.mempoolminfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: mempoolMinimumFeeKey)
            self.minrelaytxfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: minimumRelayTransactionFeeKey)
            self.incrementalrelayfee = try container.decodeIfPresent(FlexibleNumber.self, forKey: incrementalRelayFeeKey)
            self.unbroadcastcount = try container.decodeIfPresent(Int.self, forKey: unbroadcastCountKey)
            self.isFullReplaceByFeeEnabled = try container.decodeIfPresent(Bool.self, forKey: fullReplaceByFeeKey)
        }
    }
}
