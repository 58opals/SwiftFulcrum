// Response.Blockchain.UTXO+GetInfo.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.UTXO {
    public struct GetInfo: Decodable, Sendable {
        public let confirmedHeight: UInt?
        public let scriptHash: String?
        public let value: UInt?
        public let tokenData: SwiftFulcrum.CashTokens.TokenData?
        public var isFound: Bool { scriptHash != nil }

        init(
            confirmedHeight: UInt?,
            scriptHash: String?,
            value: UInt?,
            tokenData: SwiftFulcrum.CashTokens.TokenData?
        ) {
            self.confirmedHeight = confirmedHeight
            self.scriptHash = scriptHash
            self.value = value
            self.tokenData = tokenData
        }

        public init(from decoder: Decoder) throws {
            let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.UTXO.GetInfo(from: decoder)
            self.confirmedHeight = payloadModel.confirmed_height
            self.scriptHash = payloadModel.scripthash
            self.value = payloadModel.value
            self.tokenData = payloadModel.token_data
        }
    }
}

extension SwiftFulcrum.Response.Blockchain.UTXO.GetInfo: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self {
        .init(confirmedHeight: nil, scriptHash: nil, value: nil, tokenData: nil)
    }
}
