// Response.Result.Mempool+FeeHistogram.swift

import Foundation

extension SwiftFulcrum.Response.Mempool {
    public struct FeeHistogram: Decodable, Sendable {
        public let histogram: [Result]

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.GetFeeHistogram(from: decoder)
            self.histogram = try payloadModel.enumerated().map { index, pair in
                do {
                    return try Result(from: pair)
                } catch {
                    throw ResponseResultDecodeError.unexpectedFormat("Malformed fee histogram entry at index \(index)")
                }
            }
        }
    }
}
