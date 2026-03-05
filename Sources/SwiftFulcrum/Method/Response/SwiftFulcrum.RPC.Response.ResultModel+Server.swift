import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel {
    public struct Server {
        public struct Ping: SwiftFulcrum.RPC.ResponseProtocol {
            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Server.Ping?
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard jsonrpc == nil else {
                    throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Expected null result for server.ping().")
                }
            }
        }
        
        public struct Version: SwiftFulcrum.RPC.ResponseProtocol {
            public let serverVersion: String
            public let negotiatedProtocolVersion: SwiftFulcrum.ProtocolVersion
            
            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Server.Version
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard let protocolVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocolVersion) else {
                    throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Negotiated protocol version is invalid: \(jsonrpc.protocolVersion)")
                }
                
                self.serverVersion = jsonrpc.serverVersion
                self.negotiatedProtocolVersion = protocolVersion
            }
        }
        
        public struct Features: SwiftFulcrum.RPC.ResponseProtocol {
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
            
            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Server.Features
            
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                guard let minVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocol_min) else {
                    throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Minimum protocol version is invalid: \(jsonrpc.protocol_min)")
                }
                guard let maxVersion = SwiftFulcrum.ProtocolVersion(string: jsonrpc.protocol_max) else {
                    throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Maximum protocol version is invalid: \(jsonrpc.protocol_max)")
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
                
                init(from json: JSONRPCModel.Host) {
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
                
                init(from json: JSONRPCModel.ReusablePaymentAddress) {
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
