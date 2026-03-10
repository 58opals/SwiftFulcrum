// Response.Result+Mempool.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result {
    public struct Mempool {
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
        
        public struct GetFeeHistogram: Decodable, Sendable {
            public let histogram: [Result]
            
            public struct Result: Decodable, Sendable {
                public let fee: Double
                public let virtualSize: UInt
                
                init(from pair: SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.FeeHistogram) throws {
                    guard pair.count == 2 else { throw ResponseResultDecodeError.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)") }
                    let feeValue = pair[0].value
                    let virtualSizeValue = pair[1].value
                    guard feeValue.isFinite, feeValue >= 0 else { throw ResponseResultDecodeError.unexpectedFormat("Invalid fee: \(feeValue)") }
                    guard virtualSizeValue.isFinite, virtualSizeValue >= 0, virtualSizeValue <= Double(UInt.max) else { throw ResponseResultDecodeError.unexpectedFormat("Invalid vsize: \(virtualSizeValue)") }
                    
                    self.fee = feeValue
                    self.virtualSize = UInt(virtualSizeValue.rounded(.towardZero))
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.GetFeeHistogram(from: decoder)
                self.histogram = try payloadModel.enumerated().map { index, pair in
                    do { return try Result(from: pair) }
                    catch { throw ResponseResultDecodeError.unexpectedFormat("Malformed entry at index \(index): \(error)") }
                }.sorted { $0.fee < $1.fee }
            }
        }
    }
}
