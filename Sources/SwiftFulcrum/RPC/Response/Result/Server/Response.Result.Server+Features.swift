// Response.Result.Server+Features.swift

import Foundation

extension SwiftFulcrum.Response.Server {
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
            let protocolVersions = try Self.makeProtocolVersions(from: payloadModel)
            try SwiftFulcrum.Response.Blockchain.validateBlockHash(payloadModel.genesis_hash)
            guard payloadModel.hash_function == "sha256" else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Unsupported server.features hash_function: \(payloadModel.hash_function)"
                )
            }
            try Self.validateNonNegative(payloadModel.pruning, field: "pruning")

            self.genesisHash = payloadModel.genesis_hash
            self.hashFunction = payloadModel.hash_function
            self.serverVersion = payloadModel.server_version
            self.minimumProtocolVersion = protocolVersions.minimum
            self.maximumProtocolVersion = protocolVersions.maximum
            self.pruningLimit = payloadModel.pruning
            self.hosts = try Self.makeHosts(from: payloadModel.hosts)
            self.hasDoubleSpendProofs = payloadModel.hasDoubleSpendProofs
            self.hasCashTokens = payloadModel.hasCashTokens
            self.reusablePaymentAddress = try payloadModel.rpa.map { try ReusablePaymentAddress(from: $0) }
            self.hasBroadcastPackageSupport = payloadModel.hasBroadcastPackageSupport
        }

        private static func makeProtocolVersions(
            from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features
        ) throws -> (
            minimum: SwiftFulcrum.ProtocolVersion,
            maximum: SwiftFulcrum.ProtocolVersion
        ) {
            guard let minimum = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocol_min) else {
                throw ResponseResultDecodeError.unexpectedFormat("Minimum protocol version is invalid: \(payloadModel.protocol_min)")
            }
            guard let maximum = SwiftFulcrum.ProtocolVersion(string: payloadModel.protocol_max) else {
                throw ResponseResultDecodeError.unexpectedFormat("Maximum protocol version is invalid: \(payloadModel.protocol_max)")
            }
            guard SwiftFulcrum.ProtocolVersion.Range(min: minimum, max: maximum) != nil else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Server feature protocol range is invalid: \(payloadModel.protocol_min)...\(payloadModel.protocol_max)"
                )
            }

            return (minimum, maximum)
        }

        private static func makeHosts(
            from payloadHosts: [String: SwiftFulcrum.RPC.Response.JSONRPC.Result.Server.Features.Host]?
        ) throws -> [String: Host]? {
            guard let payloadHosts else { return nil }

            var hosts: [String: Host] = .init()
            hosts.reserveCapacity(payloadHosts.count)

            for (name, host) in payloadHosts {
                guard !name.isEmpty,
                      name.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
                    throw ResponseResultDecodeError.unexpectedFormat("Invalid server.features host name: \(name)")
                }
                hosts[name] = try Host(from: host)
            }

            return hosts
        }
    }
}
