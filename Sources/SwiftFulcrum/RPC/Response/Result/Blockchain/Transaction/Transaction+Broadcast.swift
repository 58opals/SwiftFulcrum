// Transaction+Broadcast.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Transaction {
    public struct Broadcast: Decodable, Sendable {
        public let transactionHash: Data

        public init(from decoder: Decoder) throws {
            let payloadModel = try String(from: decoder)
            self.transactionHash = try Self.decodeHex(payloadModel)
        }

        private static func decodeHex(_ hex: String) throws -> Data {
            let string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            guard string.count % 2 == 0 else {
                throw ResponseResultDecodeError.unexpectedFormat("txid has odd hex length: \(string.count)")
            }

            var data = Data()
            data.reserveCapacity(string.count / 2)
            var index = string.startIndex

            while index < string.endIndex {
                let currentIndex = string.index(index, offsetBy: 2)
                let byteString = String(string[index ..< currentIndex])
                guard let byte = UInt8(byteString, radix: 16) else {
                    throw ResponseResultDecodeError.unexpectedFormat("tx contains non-hex: \(byteString)")
                }
                data.append(byte)
                index = currentIndex
            }

            guard data.count == 32 else {
                throw ResponseResultDecodeError.unexpectedFormat("txid decoded \(data.count) bytes; expected 32")
            }

            return data
        }
    }
}
