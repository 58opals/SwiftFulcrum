// Response.Result+Server.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result {
    public struct Server {
        public struct Ping: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Ping?
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard jsonrpc == nil else {
                    throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Expected null result for server.ping().")
                }
            }
        }
        
        public struct Version: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let serverVersion: String
            public let negotiatedProtocolVersion: SwiftFulcrum.ProtocolVersion
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Version
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard let protocolVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocolVersion) else {
                    throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Negotiated protocol version is invalid: \(jsonrpc.protocolVersion)")
                }
                
                self.serverVersion = jsonrpc.serverVersion
                self.negotiatedProtocolVersion = protocolVersion
            }
        }
        
        public struct Features: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
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
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features
            
            public init(fromRPC jsonrpc: JSONRPC) throws {
                guard let minVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocol_min) else {
                    throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Minimum protocol version is invalid: \(jsonrpc.protocol_min)")
                }
                guard let maxVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocol_max) else {
                    throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Maximum protocol version is invalid: \(jsonrpc.protocol_max)")
                }
                
                self.genesisHash = jsonrpc.genesis_hash
                self.hashFunction = jsonrpc.hash_function
                self.serverVersion = jsonrpc.server_version
                self.minimumProtocolVersion = minVersion
                self.maximumProtocolVersion = maxVersion
                self.pruningLimit = jsonrpc.pruning
                self.hosts = jsonrpc.hosts?.mapValues { Host(from: $0) }
                self.hasDoubleSpendProofs = jsonrpc.hasDoubleSpendProofs
                self.hasCashTokens = jsonrpc.hasCashTokens
                self.reusablePaymentAddress = jsonrpc.rpa.map(ReusablePaymentAddress.init(from:))
                self.hasBroadcastPackageSupport = jsonrpc.hasBroadcastPackageSupport
            }
            
            public struct Host: Decodable, Sendable {
                public let sslPort: Int?
                public let tcpPort: Int?
                public let webSocketPort: Int?
                public let secureWebSocketPort: Int?
                
                init(from json: JSONRPC.Host) {
                    self.sslPort = json.ssl_port
                    self.tcpPort = json.tcp_port
                    self.webSocketPort = json.ws_port
                    self.secureWebSocketPort = json.wss_port
                }
            }
            
            public struct ReusablePaymentAddress: Decodable, Sendable {
                public let historyBlockLimit: Int?
                public let maximumHistoryItems: Int?
                public let indexedPrefixBits: Int?
                public let minimumPrefixBits: Int?
                public let startingHeight: Int?
                
                init(from json: JSONRPC.ReusablePaymentAddress) {
                    self.historyBlockLimit = json.history_block_limit
                    self.maximumHistoryItems = json.max_history
                    self.indexedPrefixBits = json.prefix_bits
                    self.minimumPrefixBits = json.prefix_bits_min
                    self.startingHeight = json.starting_height
                }
            }
        }
    }
    

}
