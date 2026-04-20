// Response.Result.Blockchain.Address+Subscribe.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address {
    public struct Subscribe: Decodable, Sendable {
        public let status: String?

        init(status: String?) {
            self.status = status
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe(from: decoder)
            switch payloadModel {
            case .status(let statusString):
                self.status = statusString
            case .addressAndStatus(let pair):
                throw ResponseResultDecodeError.unexpectedFormat("Expected a status string; got address and status array for Address.Subscribe: \(pair.description)")
            }
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address.Subscribe: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(status: nil) }
}
