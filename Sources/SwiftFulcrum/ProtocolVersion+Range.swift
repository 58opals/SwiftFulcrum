// ProtocolVersion+Range.swift

extension ProtocolVersion {
    public struct Range: Equatable, Sendable {
        public enum Error: Swift.Error, Equatable {
            case unsupportedVersionRange
        }
        
        public let min: ProtocolVersion
        public let max: ProtocolVersion
        
        public init?(min: ProtocolVersion, max: ProtocolVersion) {
            guard min <= max else { return nil }
            self.min = min
            self.max = max
        }
        
        public func contains(_ version: ProtocolVersion) -> Bool {
            version >= min && version <= max
        }
        
        public func chooseNegotiatedVersion(with peerRange: ProtocolVersion.Range) throws -> ProtocolVersion {
            let lowerBound = Swift.max(min, peerRange.min)
            let upperBound = Swift.min(max, peerRange.max)
            
            guard lowerBound <= upperBound else { throw Error.unsupportedVersionRange }
            return upperBound
        }
        
        public func validateNegotiatedVersion(_ version: ProtocolVersion) throws -> ProtocolVersion {
            guard contains(version) else { throw Error.unsupportedVersionRange }
            return version
        }
    }
}
