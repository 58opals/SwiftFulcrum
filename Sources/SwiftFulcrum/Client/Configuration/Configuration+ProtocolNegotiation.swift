// Configuration+ProtocolNegotiation.swift

import Foundation

extension SwiftFulcrum.Client.Configuration {
    public struct ProtocolNegotiation: Sendable {
        public var clientName: String
        public var min: SwiftFulcrum.ProtocolVersion
        public var max: SwiftFulcrum.ProtocolVersion
        public var argument: Argument {
            get throws {
                try .init(range: supportedRange)
            }
        }
        
        public var supportedRange: SwiftFulcrum.ProtocolVersion.Range {
            get throws {
                guard let range = SwiftFulcrum.ProtocolVersion.Range(min: min, max: max) else {
                    throw SwiftFulcrum.Client.Error.client(
                        .invalidProtocolNegotiationRange(
                            minimumVersion: min,
                            maximumVersion: max
                        )
                    )
                }
                
                return range
            }
        }
        
        public init(
            clientName: String = "SwiftFulcrum/\(SwiftFulcrum.Client.Configuration.resolveLibraryVersion())",
            min: SwiftFulcrum.ProtocolVersion = SwiftFulcrum.Client.Configuration.defaultMinimumProtocolVersion,
            max: SwiftFulcrum.ProtocolVersion = SwiftFulcrum.Client.Configuration.defaultMaximumProtocolVersion
        ) {
            self.clientName = clientName
            self.min = min
            self.max = max
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
