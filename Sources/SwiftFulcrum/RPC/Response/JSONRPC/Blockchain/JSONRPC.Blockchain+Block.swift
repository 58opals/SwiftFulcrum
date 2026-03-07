// JSONRPC.Blockchain+Block.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    public struct Block {
        public typealias Header = HeaderParameters

        public enum HeaderParameters: Decodable, Sendable {
            case raw(String)
            case proof(Proof)

            public struct Proof: Decodable, Sendable {
                public let branch: [String]
                public let header: String
                public let root: String
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                if let singleValue = try? container.decode(String.self) {
                    self = .raw(singleValue)
                    return
                }

                if let multipleValues = try? container.decode(Proof.self) {
                    self = .proof(multipleValues)
                    return
                }

                throw DecodingError.typeMismatch(
                    HeaderParameters.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Proof dictionary")
                )
            }
        }

        public struct Headers: Decodable, Sendable {
            public let count: UInt
            public let hex: String
            public let max: UInt
            public let root: String?
            public let branch: [String]?
            public let headers: [String]?

            public init(from decoder: Decoder) throws {
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
}
