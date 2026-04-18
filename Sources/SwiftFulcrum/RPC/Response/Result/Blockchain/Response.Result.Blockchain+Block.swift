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
                self.headers = try Self.resolveHeaders(from: payloadModel)
                self.max = payloadModel.max
                switch (payloadModel.branch, payloadModel.root) {
                case let (.some(branch), .some(root)):
                    self.proof = Block.Header.Proof(branch: branch, root: root)
                case (nil, nil):
                    self.proof = nil
                case (.some, nil), (nil, .some):
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected block.headers proof metadata to include both branch and root"
                    )
                }
            }

            private static func resolveHeaders(
                from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Headers
            ) throws -> [String] {
                let headers: [String]
                if let providedHeaders = payloadModel.headers {
                    headers = providedHeaders
                    try validateHeaderLengths(headers)
                } else {
                    headers = try splitHeaders(hex: payloadModel.hex)
                }

                guard headers.count == Int(payloadModel.count) else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected \(payloadModel.count) block headers; decoded \(headers.count)"
                    )
                }

                return headers
            }

            private static func validateHeaderLengths(_ headers: [String]) throws {
                let headerCharacterLength = 160
                guard headers.allSatisfy({ $0.count == headerCharacterLength }) else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected each block header to be exactly \(headerCharacterLength) hex characters"
                    )
                }
            }

            private static func splitHeaders(hex: String) throws -> [String] {
                let headerCharacterLength = 160

                guard hex.count.isMultiple(of: headerCharacterLength) else {
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected concatenated block headers hex to be a multiple of \(headerCharacterLength) characters"
                    )
                }

                var headers: [String] = .init()
                var currentIndex = hex.startIndex

                while currentIndex < hex.endIndex {
                    let endIndex = hex.index(
                        currentIndex,
                        offsetBy: headerCharacterLength,
                        limitedBy: hex.endIndex
                    )!

                    headers.append(String(hex[currentIndex ..< endIndex]))
                    currentIndex = endIndex
                }

                return headers
            }
        }
    }
}
