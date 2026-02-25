import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel {
        public struct ServerModel {
            public struct PingModel: Decodable, Sendable {}
            
            public struct VersionModel: Decodable, Sendable {
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
            
            public struct FeaturesModel: Decodable, Sendable {
                public let genesis_hash: String
                public let hash_function: String
                public let server_version: String
                public let protocol_max: String
                public let protocol_min: String
                public let pruning: Int?
                public let hosts: [String: HostModel]?
                public let hasDoubleSpendProofs: Bool?
                public let hasCashTokens: Bool?
                public let rpa: ReusablePaymentAddressModel?
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
                
                public struct HostModel: Decodable, Sendable {
                    public let ssl_port: Int?
                    public let tcp_port: Int?
                    public let ws_port: Int?
                    public let wss_port: Int?
                }
                
                public struct ReusablePaymentAddressModel: Decodable, Sendable {
                    public let history_block_limit: Int?
                    public let max_history: Int?
                    public let prefix_bits: Int?
                    public let prefix_bits_min: Int?
                    public let starting_height: Int?
                }
            }
        }
        

}
