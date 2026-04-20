// JSONRPC.Blockchain.Block+Headers.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block {
    struct Headers: Decodable, Sendable {
        let count: UInt
        let hex: String
        let max: UInt
        let root: String?
        let branch: [String]?
        let headers: [String]?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKeyModel.self)
            let countKey = JSONRPCResponseDecodeModel.CodingKeyModel("count")
            let hexKey = JSONRPCResponseDecodeModel.CodingKeyModel("hex")
            let headersKey = JSONRPCResponseDecodeModel.CodingKeyModel("headers")
            let maxKey = JSONRPCResponseDecodeModel.CodingKeyModel("max")
            let rootKey = JSONRPCResponseDecodeModel.CodingKeyModel("root")
            let branchKey = JSONRPCResponseDecodeModel.CodingKeyModel("branch")

            self.count = try container.decode(UInt.self, forKey: countKey)
            self.max = try container.decode(UInt.self, forKey: maxKey)
            self.headers = try container.decodeIfPresent([String].self, forKey: headersKey)

            if let headerList = headers {
                self.hex = headerList.joined()
            } else if let legacyHex = try container.decodeIfPresent(String.self, forKey: hexKey) {
                self.hex = legacyHex
            } else {
                throw DecodingError.valueNotFound(
                    String.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected either hex or headers fields")
                )
            }

            self.root = try container.decodeIfPresent(String.self, forKey: rootKey)
            self.branch = try container.decodeIfPresent([String].self, forKey: branchKey)
        }
    }
}
