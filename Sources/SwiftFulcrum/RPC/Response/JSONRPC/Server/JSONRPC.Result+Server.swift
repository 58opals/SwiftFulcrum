// JSONRPC.Result+Server.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
        public struct Server {
            public struct Ping: Decodable, Sendable {}
            
            public struct Version: Decodable, Sendable {
                public let serverVersion: String
                public let protocolVersion: String
                
                public init(from decoder: Decoder) throws {
                    var container = try decoder.unkeyedContainer()
                    guard !container.isAtEnd else {
                        throw DecodingError.dataCorruptedError(in: container,
                                                               debugDescription: "Expected server and protocol version pair")
                    }
                    
                    self.serverVersion = try container.decode(String.self)
                    guard !container.isAtEnd else {
                        throw DecodingError.dataCorruptedError(in: container,
                                                               debugDescription: "Missing negotiated protocol version")
                    }
                    self.protocolVersion = try container.decode(String.self)
                }
            }
            
            public struct Features: Decodable, Sendable {
                public let genesis_hash: String
                public let hash_function: String
                public let server_version: String
                public let protocol_max: String
                public let protocol_min: String
                public let pruning: Int?
                public let hosts: [String: Host]?
                public let hasDoubleSpendProofs: Bool?
                public let hasCashTokens: Bool?
                public let rpa: ReusablePaymentAddress?
                public let hasBroadcastPackageSupport: Bool?

                public init(from decoder: Decoder) throws {
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
                
                public struct Host: Decodable, Sendable {
                    public let ssl_port: Int?
                    public let tcp_port: Int?
                    public let ws_port: Int?
                    public let wss_port: Int?
                }
                
                public struct ReusablePaymentAddress: Decodable, Sendable {
                    public let history_block_limit: Int?
                    public let max_history: Int?
                    public let prefix_bits: Int?
                    public let prefix_bits_min: Int?
                    public let starting_height: Int?
                }
            }
        }
        

}
