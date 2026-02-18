//  FulcrumClient+Configuration+ProtocolNegotiationModel.swift

import Foundation

extension FulcrumClient.Configuration {
    public struct ProtocolNegotiationModel: Sendable {
        public var clientName: String
        public var min: ProtocolVersionModel
        public var max: ProtocolVersionModel
        public var argument: ArgumentModel { .init(range: supportedRange) }
        
        public var supportedRange: ProtocolVersionModel.RangeModel {
            guard let range = ProtocolVersionModel.RangeModel(min: min, max: max) else {
                preconditionFailure("Protocol negotiation range must define a valid minimum and maximum")
            }
            
            return range
        }
        
        public init(
            clientName: String = "SwiftFulcrum/\(FulcrumClient.Configuration.resolveLibraryVersion())",
            min: ProtocolVersionModel = FulcrumClient.Configuration.defaultMinimumProtocolVersion,
            max: ProtocolVersionModel = FulcrumClient.Configuration.defaultMaximumProtocolVersion
        ) {
            self.clientName = clientName
            self.min = min
            self.max = max
        }
    }
}

extension FulcrumClient.Configuration.ProtocolNegotiationModel {
    public struct ArgumentModel: Encodable, Sendable {
        public let minimumVersion: ProtocolVersionModel
        public let maximumVersion: ProtocolVersionModel
        
        public init(minimumVersion: ProtocolVersionModel, maximumVersion: ProtocolVersionModel) {
            precondition(minimumVersion <= maximumVersion, "Minimum protocol version cannot exceed maximum protocol version")
            self.minimumVersion = minimumVersion
            self.maximumVersion = maximumVersion
        }
        
        public init(range: ProtocolVersionModel.RangeModel) {
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

extension FulcrumClient.Configuration {
    public static var defaultMinimumProtocolVersion: ProtocolVersionModel {
        guard let version = ProtocolVersionModel(string: "1.4") else {
            preconditionFailure("Default minimum protocol version must be valid")
        }
        
        return version
    }
    
    public static var defaultMaximumProtocolVersion: ProtocolVersionModel {
        guard let version = ProtocolVersionModel(string: "1.6.0") else {
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
