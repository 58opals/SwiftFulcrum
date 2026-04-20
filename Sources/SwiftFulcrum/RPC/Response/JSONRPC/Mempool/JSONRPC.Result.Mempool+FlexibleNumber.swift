// JSONRPC.Result.Mempool+FlexibleNumber.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool {
    struct FlexibleNumber: Decodable, Sendable {
        let value: Double

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let double = try? container.decode(Double.self) {
                self.value = double
                return
            }
            if let int = try? container.decode(Int.self) {
                self.value = Double(int)
                return
            }
            if let uint = try? container.decode(UInt.self) {
                self.value = Double(uint)
                return
            }
            if let string = try? container.decode(String.self), let double = Double(string) {
                self.value = double
                return
            }

            throw DecodingError.typeMismatch(
                Double.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected number or numeric string")
            )
        }
    }
}
