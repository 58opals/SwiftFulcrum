// JSONRPC.Result+Mempool.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
    struct Mempool {
        struct FlexibleNumber: Decodable, Sendable {
            let value: Double

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let double = try? container.decode(Double.self) { self.value = double; return }
                if let int = try? container.decode(Int.self) { self.value = Double(int); return }
                if let uint = try? container.decode(UInt.self) { self.value = Double(uint); return }
                if let string = try? container.decode(String.self), let double = Double(string) { self.value = double; return }

                throw DecodingError.typeMismatch(
                    Double.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected number or numeric string")
                )
            }
        }

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

        typealias FeeHistogram = [FlexibleNumber]
        typealias GetFeeHistogram = [FeeHistogram]
    }
}
