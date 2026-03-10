// JSONRPC.Result+Server.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
    struct Server {
        struct Ping: Decodable, Sendable {}

        struct Version: Decodable, Sendable {
            let serverVersion: String
            let protocolVersion: String

            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                guard !container.isAtEnd else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Expected server and protocol version pair"
                    )
                }

                self.serverVersion = try container.decode(String.self)
                guard !container.isAtEnd else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Missing negotiated protocol version"
                    )
                }

                self.protocolVersion = try container.decode(String.self)
            }
        }

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
                let container = try decoder.container(keyedBy: JSONRPCResponseDecodeModel.CodingKeyModel.self)
                let genesisHashKey = JSONRPCResponseDecodeModel.CodingKeyModel("genesis_hash")
                let hashFunctionKey = JSONRPCResponseDecodeModel.CodingKeyModel("hash_function")
                let serverVersionKey = JSONRPCResponseDecodeModel.CodingKeyModel("server_version")
                let protocolMaxKey = JSONRPCResponseDecodeModel.CodingKeyModel("protocol_max")
                let protocolMinKey = JSONRPCResponseDecodeModel.CodingKeyModel("protocol_min")
                let pruningKey = JSONRPCResponseDecodeModel.CodingKeyModel("pruning")
                let hostsKey = JSONRPCResponseDecodeModel.CodingKeyModel("hosts")
                let doubleSpendProofsKey = JSONRPCResponseDecodeModel.CodingKeyModel("dsproof")
                let cashTokensKey = JSONRPCResponseDecodeModel.CodingKeyModel("cashtokens")
                let reusablePaymentAddressKey = JSONRPCResponseDecodeModel.CodingKeyModel("rpa")
                let broadcastPackageKey = JSONRPCResponseDecodeModel.CodingKeyModel("broadcast_package")

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

            struct Host: Decodable, Sendable {
                let ssl_port: Int?
                let tcp_port: Int?
                let ws_port: Int?
                let wss_port: Int?
            }

            struct ReusablePaymentAddress: Decodable, Sendable {
                let history_block_limit: Int?
                let max_history: Int?
                let prefix_bits: Int?
                let prefix_bits_min: Int?
                let starting_height: Int?
            }
        }
    }
}
