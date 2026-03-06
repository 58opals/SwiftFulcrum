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

                enum CodingKeys: String, CodingKey {
                    case genesis_hash
                    case hash_function
                    case server_version
                    case protocol_max
                    case protocol_min
                    case pruning
                    case hosts
                    case hasDoubleSpendProofs = "dsproof"
                    case hasCashTokens = "cashtokens"
                    case rpa
                    case hasBroadcastPackageSupport = "broadcast_package"
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.genesis_hash = try container.decode(String.self, forKey: .genesis_hash)
                    self.hash_function = try container.decode(String.self, forKey: .hash_function)
                    self.server_version = try container.decode(String.self, forKey: .server_version)
                    self.protocol_max = try container.decode(String.self, forKey: .protocol_max)
                    self.protocol_min = try container.decode(String.self, forKey: .protocol_min)
                    self.pruning = try container.decodeIfPresent(Int.self, forKey: .pruning)
                    self.hosts = try container.decodeIfPresent([String: Host].self, forKey: .hosts)
                    self.hasDoubleSpendProofs = try container.decodeIfPresent(Bool.self, forKey: .hasDoubleSpendProofs)
                    self.hasCashTokens = try container.decodeIfPresent(Bool.self, forKey: .hasCashTokens)
                    self.rpa = try container.decodeIfPresent(ReusablePaymentAddress.self, forKey: .rpa)
                    self.hasBroadcastPackageSupport = try container.decodeIfPresent(Bool.self, forKey: .hasBroadcastPackageSupport)
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
