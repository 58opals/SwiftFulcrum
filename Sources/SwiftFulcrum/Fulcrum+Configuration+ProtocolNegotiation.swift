//  Fulcrum+Configuration+ProtocolNegotiation.swift

import Foundation

extension Fulcrum.Configuration {
    public struct ProtocolNegotiation: Sendable {
        public var clientName: String
        public var min: ProtocolVersion
        public var max: ProtocolVersion
        public var argument: Argument { .init(range: supportedRange) }
        
        public var supportedRange: ProtocolVersion.Range {
            guard let range = ProtocolVersion.Range(min: min, max: max) else {
                preconditionFailure("Protocol negotiation range must define a valid minimum and maximum")
            }
            
            return range
        }
        
        public init(
            clientName: String = "SwiftFulcrum/\(Fulcrum.Configuration.resolveLibraryVersion())",
            min: ProtocolVersion = Fulcrum.Configuration.defaultMinimumProtocolVersion,
            max: ProtocolVersion = Fulcrum.Configuration.defaultMaximumProtocolVersion
        ) {
            self.clientName = clientName
            self.min = min
            self.max = max
        }
    }
}

extension Fulcrum.Configuration.ProtocolNegotiation {
    public struct Argument: Encodable, Sendable {
        public let minimumVersion: ProtocolVersion
        public let maximumVersion: ProtocolVersion
        
        public init(minimumVersion: ProtocolVersion, maximumVersion: ProtocolVersion) {
            precondition(minimumVersion <= maximumVersion, "Minimum protocol version cannot exceed maximum protocol version")
            self.minimumVersion = minimumVersion
            self.maximumVersion = maximumVersion
        }
        
        public init(range: ProtocolVersion.Range) {
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

extension Fulcrum.Configuration {
    public static var defaultMinimumProtocolVersion: ProtocolVersion {
        guard let version = ProtocolVersion(string: "1.4") else {
            preconditionFailure("Default minimum protocol version must be valid")
        }
        
        return version
    }
    
    public static var defaultMaximumProtocolVersion: ProtocolVersion {
        guard let version = ProtocolVersion(string: "1.6.0") else {
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
