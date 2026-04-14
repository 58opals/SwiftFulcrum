// Configuration+ProtocolNegotiation.swift

import Foundation

extension SwiftFulcrum.Client.Configuration {
    public struct ProtocolNegotiation: Sendable {
        public let clientName: String
        public let minimumVersion: SwiftFulcrum.ProtocolVersion
        public let maximumVersion: SwiftFulcrum.ProtocolVersion
        public let supportedRange: SwiftFulcrum.ProtocolVersion.Range

        public init() {
            let minimumVersion = SwiftFulcrum.Client.Configuration.defaultMinimumProtocolVersion
            let maximumVersion = SwiftFulcrum.Client.Configuration.defaultMaximumProtocolVersion
            let supportedRange = SwiftFulcrum.ProtocolVersion.Range(
                min: minimumVersion,
                max: maximumVersion
            )!

            self.init(
                clientName: SwiftFulcrum.Client.Configuration.defaultClientName,
                minimumVersion: minimumVersion,
                maximumVersion: maximumVersion,
                supportedRange: supportedRange
            )
        }

        public init(
            clientName: String = SwiftFulcrum.Client.Configuration.defaultClientName,
            minimumVersion: SwiftFulcrum.ProtocolVersion,
            maximumVersion: SwiftFulcrum.ProtocolVersion
        ) throws {
            guard let supportedRange = SwiftFulcrum.ProtocolVersion.Range(
                min: minimumVersion,
                max: maximumVersion
            ) else {
                throw SwiftFulcrum.Client.Error.client(
                    .invalidProtocolNegotiationRange(
                        minimumVersion: minimumVersion,
                        maximumVersion: maximumVersion
                    )
                )
            }

            self.init(
                clientName: clientName,
                minimumVersion: minimumVersion,
                maximumVersion: maximumVersion,
                supportedRange: supportedRange
            )
        }

        public func makeArgument() -> Argument {
            .init(range: supportedRange)
        }

        init(
            clientName: String,
            minimumVersion: SwiftFulcrum.ProtocolVersion,
            maximumVersion: SwiftFulcrum.ProtocolVersion,
            supportedRange: SwiftFulcrum.ProtocolVersion.Range
        ) {
            self.clientName = clientName
            self.minimumVersion = minimumVersion
            self.maximumVersion = maximumVersion
            self.supportedRange = supportedRange
        }
    }
}

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

extension SwiftFulcrum.Client.Configuration {
    public static var defaultClientName: String {
        "SwiftFulcrum/\(resolveLibraryVersion())"
    }

    public static var defaultMinimumProtocolVersion: SwiftFulcrum.ProtocolVersion {
        guard let version = SwiftFulcrum.ProtocolVersion(string: "1.4") else {
            preconditionFailure("Default minimum protocol version must be valid")
        }
        
        return version
    }
    
    public static var defaultMaximumProtocolVersion: SwiftFulcrum.ProtocolVersion {
        guard let version = SwiftFulcrum.ProtocolVersion(string: "1.6.0") else {
            preconditionFailure("Default maximum protocol version must be valid")
        }
        
        return version
    }
    
    public static func resolveLibraryVersion() -> String {
        if let shortVersion = Bundle.module.infoDictionary?["CFBundleShortVersionString"] as? String {
            return shortVersion
        }
        
        if let bundleVersion = Bundle.module.infoDictionary?["CFBundleVersion"] as? String {
            return bundleVersion
        }
        
        return "unknown"
    }
}
