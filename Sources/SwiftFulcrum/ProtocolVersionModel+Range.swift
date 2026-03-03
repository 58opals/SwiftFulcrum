// ProtocolVersionModel+Range.swift

extension ProtocolVersionModel {
    public struct Range: Equatable, Sendable {
        public enum Error: Swift.Error, Equatable {
            case unsupportedVersionRange
        }
        
        public let min: ProtocolVersionModel
        public let max: ProtocolVersionModel
        
        public init?(min: ProtocolVersionModel, max: ProtocolVersionModel) {
            guard min <= max else { return nil }
            self.min = min
            self.max = max
        }
        
        public func contains(_ version: ProtocolVersionModel) -> Bool {
            version >= min && version <= max
        }
        
        public func chooseNegotiatedVersion(with peerRange: ProtocolVersionModel.Range) throws -> ProtocolVersionModel {
            let lowerBound = Swift.max(min, peerRange.min)
            let upperBound = Swift.min(max, peerRange.max)
            
            guard lowerBound <= upperBound else { throw Error.unsupportedVersionRange }
            return upperBound
        }
        
        public func validateNegotiatedVersion(_ version: ProtocolVersionModel) throws -> ProtocolVersionModel {
            guard contains(version) else { throw Error.unsupportedVersionRange }
            return version
        }
    }
}
