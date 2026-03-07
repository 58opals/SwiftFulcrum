// ProtocolVersion.swift

import Foundation

extension SwiftFulcrum {
    public struct ProtocolVersion: Comparable, CustomStringConvertible, Decodable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    private let isPatchComponentIncluded: Bool
    
    public init?(major: Int, minor: Int, patch: Int = 0, isPatchComponentIncluded: Bool? = nil) {
        guard major >= 0, minor >= 0, patch >= 0 else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
        self.isPatchComponentIncluded = isPatchComponentIncluded ?? (patch != 0)
    }
    
    public init?(string: String) {
        let components = string.split(separator: ".").map(String.init)
        guard (2 ... 3).contains(components.count) else { return nil }
        
        let integers = components.compactMap { Int($0) }
        guard integers.count == components.count else { return nil }
        
        switch integers.count {
        case 2:
            self.init(major: integers[0], minor: integers[1], patch: 0, isPatchComponentIncluded: false)
        case 3:
            self.init(major: integers[0], minor: integers[1], patch: integers[2], isPatchComponentIncluded: true)
        default:
            return nil
        }
    }
    
    public var description: String {
        if !isPatchComponentIncluded && patch == 0 {
            return "\(major).\(minor)"
        }
        
        return "\(major).\(minor).\(patch)"
    }
    
    public static func < (lhs: SwiftFulcrum.ProtocolVersion, rhs: SwiftFulcrum.ProtocolVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        
        return lhs.patch < rhs.patch
    }
    }
}
