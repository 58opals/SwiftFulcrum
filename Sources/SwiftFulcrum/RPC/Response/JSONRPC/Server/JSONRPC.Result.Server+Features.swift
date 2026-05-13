// JSONRPC.Result.Server+Features.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Server {
    struct Features: Decodable, Sendable {
        let genesis_hash: String
        let hash_function: String
        let server_version: String
        let protocol_max: String
        let protocol_min: String
        let pruning: Int?
        let hosts: [String: Host]?
        let hasDoubleSpendProofs: Bool?
        let hasCashTokens: Bool?
        let rpa: ReusablePaymentAddress?
        let hasBroadcastPackageSupport: Bool?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKey.self)
            let genesisHashKey = JSONRPCResponseDecodeModel.CodingKey("genesis_hash")
            let hashFunctionKey = JSONRPCResponseDecodeModel.CodingKey("hash_function")
            let serverVersionKey = JSONRPCResponseDecodeModel.CodingKey("server_version")
            let protocolMaxKey = JSONRPCResponseDecodeModel.CodingKey("protocol_max")
            let protocolMinKey = JSONRPCResponseDecodeModel.CodingKey("protocol_min")
            let pruningKey = JSONRPCResponseDecodeModel.CodingKey("pruning")
            let hostsKey = JSONRPCResponseDecodeModel.CodingKey("hosts")
            let doubleSpendProofsKey = JSONRPCResponseDecodeModel.CodingKey("dsproof")
            let cashTokensKey = JSONRPCResponseDecodeModel.CodingKey("cashtokens")
            let reusablePaymentAddressKey = JSONRPCResponseDecodeModel.CodingKey("rpa")
            let broadcastPackageKey = JSONRPCResponseDecodeModel.CodingKey("broadcast_package")

            self.genesis_hash = try container.decode(String.self, forKey: genesisHashKey)
            self.hash_function = try container.decode(String.self, forKey: hashFunctionKey)
            self.server_version = try container.decode(String.self, forKey: serverVersionKey)
            self.protocol_max = try container.decode(String.self, forKey: protocolMaxKey)
            self.protocol_min = try container.decode(String.self, forKey: protocolMinKey)
            self.pruning = try container.decodeIfPresent(Int.self, forKey: pruningKey)
            self.hosts = try container.decodeIfPresent([String: Host].self, forKey: hostsKey)
            self.hasDoubleSpendProofs = try container.decodeIfPresent(Bool.self, forKey: doubleSpendProofsKey)
            self.hasCashTokens = try container.decodeIfPresent(Bool.self, forKey: cashTokensKey)
            self.rpa = try container.decodeIfPresent(ReusablePaymentAddress.self, forKey: reusablePaymentAddressKey)
            self.hasBroadcastPackageSupport = try container.decodeIfPresent(Bool.self, forKey: broadcastPackageKey)
        }
    }
}
