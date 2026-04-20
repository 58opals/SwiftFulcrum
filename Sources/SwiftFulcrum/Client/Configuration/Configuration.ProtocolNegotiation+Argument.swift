// Configuration.ProtocolNegotiation+Argument.swift

import Foundation

extension SwiftFulcrum.Client.Configuration.ProtocolNegotiation {
    public struct Argument: Encodable, Sendable {
        public let minimumVersion: SwiftFulcrum.ProtocolVersion
        public let maximumVersion: SwiftFulcrum.ProtocolVersion

        public init(minimumVersion: SwiftFulcrum.ProtocolVersion, maximumVersion: SwiftFulcrum.ProtocolVersion) throws {
            guard minimumVersion <= maximumVersion else {
                throw SwiftFulcrum.Client.Error.client(
                    .invalidProtocolNegotiationRange(
                        minimumVersion: minimumVersion,
                        maximumVersion: maximumVersion
                    )
                )
            }
            self.minimumVersion = minimumVersion
            self.maximumVersion = maximumVersion
        }

        public init(range: SwiftFulcrum.ProtocolVersion.Range) {
            self.minimumVersion = range.min
            self.maximumVersion = range.max
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            if minimumVersion == maximumVersion {
                try container.encode(minimumVersion.description)
                return
            }

            try container.encode([minimumVersion.description, maximumVersion.description])
        }
    }
}
