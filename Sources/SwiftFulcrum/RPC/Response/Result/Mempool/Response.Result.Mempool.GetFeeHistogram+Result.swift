// Response.Mempool.GetFeeHistogram+Result.swift

import Foundation

extension SwiftFulcrum.Response.Mempool.GetFeeHistogram {
    public struct Result: Decodable, Sendable {
        public let fee: Double
        public let virtualSize: UInt

        init(from pair: SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.FeeHistogram) throws {
            guard pair.count == 2 else {
                throw ResponseResultDecodeError.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)")
            }
            let feeValue = pair[0].value
            let virtualSizeValue = pair[1].value
            guard feeValue.isFinite, feeValue >= 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid fee: \(feeValue)")
            }
            let truncatedVirtualSizeValue = virtualSizeValue.rounded(.towardZero)
            let maximumConvertibleVirtualSize = Double(UInt.max).nextDown
            guard truncatedVirtualSizeValue.isFinite,
                  truncatedVirtualSizeValue >= 0,
                  truncatedVirtualSizeValue <= maximumConvertibleVirtualSize else {
                throw ResponseResultDecodeError.unexpectedFormat("Invalid vsize: \(virtualSizeValue)")
            }

            self.fee = feeValue
            self.virtualSize = UInt(truncatedVirtualSizeValue)
        }
    }
}
