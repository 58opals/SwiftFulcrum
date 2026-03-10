// Response.Result+Server.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result {
    public struct Server {
        public struct Ping: Decodable, Sendable {
            init() {}

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Ping(from: decoder)
                _ = payloadModel
            }
        }
        
        public struct Version: Decodable, Sendable {
            public let serverVersion: String
            public let negotiatedProtocolVersion: SwiftFulcrum.ProtocolVersion

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Version(from: decoder)

                guard let protocolVersion = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocolVersion) else {
                    throw ResponseResultDecodeError.unexpectedFormat("Negotiated protocol version is invalid: \(payloadModel.protocolVersion)")
                }
                
                self.serverVersion = payloadModel.serverVersion
                self.negotiatedProtocolVersion = protocolVersion
            }
        }
        
        public struct Features: Decodable, Sendable {
            public let genesisHash: String
            public let hashFunction: String
            public let serverVersion: String
            public let minimumProtocolVersion: SwiftFulcrum.ProtocolVersion
            public let maximumProtocolVersion: SwiftFulcrum.ProtocolVersion
            public let pruningLimit: Int?
            public let hosts: [String: Host]?
            public let hasDoubleSpendProofs: Bool?
            public let hasCashTokens: Bool?
            public let reusablePaymentAddress: ReusablePaymentAddress?
            public let hasBroadcastPackageSupport: Bool?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features(from: decoder)

                guard let minVersion = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocol_min) else {
                    throw ResponseResultDecodeError.unexpectedFormat("Minimum protocol version is invalid: \(payloadModel.protocol_min)")
                }
                guard let maxVersion = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocol_max) else {
                    throw ResponseResultDecodeError.unexpectedFormat("Maximum protocol version is invalid: \(payloadModel.protocol_max)")
                }
                
                self.genesisHash = payloadModel.genesis_hash
                self.hashFunction = payloadModel.hash_function
                self.serverVersion = payloadModel.server_version
                self.minimumProtocolVersion = minVersion
                self.maximumProtocolVersion = maxVersion
                self.pruningLimit = payloadModel.pruning
                self.hosts = payloadModel.hosts?.mapValues { Host(from: $0) }
                self.hasDoubleSpendProofs = payloadModel.hasDoubleSpendProofs
                self.hasCashTokens = payloadModel.hasCashTokens
                self.reusablePaymentAddress = payloadModel.rpa.map(ReusablePaymentAddress.init(from:))
                self.hasBroadcastPackageSupport = payloadModel.hasBroadcastPackageSupport
            }
            
            public struct Host: Decodable, Sendable {
                public let sslPort: Int?
                public let tcpPort: Int?
                public let webSocketPort: Int?
                public let secureWebSocketPort: Int?
                
                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.Host) {
                    self.sslPort = payloadModel.ssl_port
                    self.tcpPort = payloadModel.tcp_port
                    self.webSocketPort = payloadModel.ws_port
                    self.secureWebSocketPort = payloadModel.wss_port
                }
            }
            
            public struct ReusablePaymentAddress: Decodable, Sendable {
                public let historyBlockLimit: Int?
                public let maximumHistoryItems: Int?
                public let indexedPrefixBits: Int?
                public let minimumPrefixBits: Int?
                public let startingHeight: Int?
                
                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.ReusablePaymentAddress) {
                    self.historyBlockLimit = payloadModel.history_block_limit
                    self.maximumHistoryItems = payloadModel.max_history
                    self.indexedPrefixBits = payloadModel.prefix_bits
                    self.minimumPrefixBits = payloadModel.prefix_bits_min
                    self.startingHeight = payloadModel.starting_height
                }
            }
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Server.Ping: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init() }
}
