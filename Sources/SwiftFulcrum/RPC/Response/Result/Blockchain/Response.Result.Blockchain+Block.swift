// Response.Result.Blockchain+Block.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct Block {
        public struct Header: Decodable, Sendable {
            public let hex: String
            public let proof: Proof?

            public struct Proof: Decodable, Sendable {
                public let branch: [String]
                public let root: String
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Header(from: decoder)
                switch payloadModel {
                case .raw(let raw):
                    self.hex = raw
                    self.proof = nil
                case .proof(let proof):
                    self.hex = proof.header
                    self.proof = Proof(branch: proof.branch, root: proof.root)
                }
            }
        }
        
        public struct Headers: Decodable, Sendable {
            public let count: UInt
            public let headers: [String]
            public let hex: String
            public let max: UInt
            public let proof: Block.Header.Proof?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Headers(from: decoder)
                self.count = payloadModel.count
                self.hex = payloadModel.hex
                self.headers = payloadModel.headers ?? Self.splitHeaders(hex: payloadModel.hex)
                self.max = payloadModel.max
                self.proof = {
                    guard let branch = payloadModel.branch,
                          let root = payloadModel.root else {
                        return nil
                    }
                    return Block.Header.Proof(branch: branch, root: root)
                }()
            }

            private static func splitHeaders(hex: String) -> [String] {
                let headerCharacterLength = 160
                var headers: [String] = .init()
                var currentIndex = hex.startIndex

                while currentIndex < hex.endIndex {
                    guard let endIndex = hex.index(
                        currentIndex,
                        offsetBy: headerCharacterLength,
                        limitedBy: hex.endIndex
                    ) else {
                        break
                    }

                    guard hex.distance(from: currentIndex, to: endIndex) == headerCharacterLength else {
                        break
                    }

                    headers.append(String(hex[currentIndex ..< endIndex]))
                    currentIndex = endIndex
                }

                return headers
            }
        }
    }
}
