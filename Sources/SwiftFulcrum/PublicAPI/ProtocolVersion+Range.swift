// ProtocolVersion+Range.swift

extension SwiftFulcrum.ProtocolVersion {
    public struct Range: Equatable, Sendable {
        public let min: SwiftFulcrum.ProtocolVersion
        public let max: SwiftFulcrum.ProtocolVersion
        
        public init?(min: SwiftFulcrum.ProtocolVersion, max: SwiftFulcrum.ProtocolVersion) {
            guard min <= max else { return nil }
            self.min = min
            self.max = max
        }
        
        public func contains(_ version: SwiftFulcrum.ProtocolVersion) -> Bool {
            version >= min && version <= max
        }
        
        public func chooseNegotiatedVersion(with peerRange: SwiftFulcrum.ProtocolVersion.Range) throws -> SwiftFulcrum.ProtocolVersion {
            let lowerBound = Swift.max(min, peerRange.min)
            let upperBound = Swift.min(max, peerRange.max)
            
            guard lowerBound <= upperBound else { throw Error.unsupportedVersionRange }
            return upperBound
        }
        
        public func validateNegotiatedVersion(_ version: SwiftFulcrum.ProtocolVersion) throws -> SwiftFulcrum.ProtocolVersion {
            guard contains(version) else { throw Error.unsupportedVersionRange }
            return version
        }
    }
}
