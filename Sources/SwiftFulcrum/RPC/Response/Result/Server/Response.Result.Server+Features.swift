// Response.Result.Server+Features.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Server {
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
            guard SwiftFulcrum.ProtocolVersion.Range(min: minVersion, max: maxVersion) != nil else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Server feature protocol range is invalid: \(payloadModel.protocol_min)...\(payloadModel.protocol_max)"
                )
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
    }
}
