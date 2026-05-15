// Response.Result.Blockchain.Block+Headers.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Block {
    public struct Headers: Decodable, Sendable {
        public let count: UInt
        public let headers: [String]
        public let hex: String
        public let max: UInt
        public let proof: SwiftFulcrum.Response.Blockchain.Block.Header.Proof?

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Block.Headers(from: decoder)
            self.count = payloadModel.count
            self.hex = payloadModel.hex
            self.headers = try Self.resolveHeaders(from: payloadModel)
            self.max = payloadModel.max
            switch (payloadModel.branch, payloadModel.root) {
            case let (.some(branch), .some(root)):
                self.proof = SwiftFulcrum.Response.Blockchain.Block.Header.Proof(branch: branch, root: root)
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
                try SwiftFulcrum.Response.Blockchain.validateBlockHeaderLengths(headers)
            } else {
                headers = try splitHeaders(hex: payloadModel.hex)
            }

            guard payloadModel.count <= UInt(Int.max) else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Block header count exceeds platform maximum: \(payloadModel.count)"
                )
            }

            guard headers.count == Int(payloadModel.count) else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected \(payloadModel.count) block headers; decoded \(headers.count)"
                )
            }

            return headers
        }

        private static func splitHeaders(hex: String) throws -> [String] {
            let headerCharacterLength = SwiftFulcrum.Response.Blockchain.blockHeaderCharacterLength

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
