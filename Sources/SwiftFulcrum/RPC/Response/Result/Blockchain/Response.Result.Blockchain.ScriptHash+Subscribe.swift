// Response.Result.Blockchain.ScriptHash+Subscribe.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.ScriptHash {
    public struct Subscribe: Decodable, Sendable {
        public let status: String?

        init(status: String?) {
            self.status = status
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe(from: decoder)

            switch payloadModel {
            case .status(let statusString):
                self.status = statusString
            case .scripthashAndStatus(let pair):
                throw ResponseResultDecodeError.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHash.Subscribe: \(pair.description)")
            }
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.ScriptHash.Subscribe: JSONRPCResponseDecodeModel.NilValue {
    static var nilValue: Self { .init(status: nil) }
}
