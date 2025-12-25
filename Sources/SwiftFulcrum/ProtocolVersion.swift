// ProtocolVersion.swift

import Foundation

public struct ProtocolVersion: Comparable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    private let includesPatchComponent: Bool
    
    public init?(major: Int, minor: Int, patch: Int = 0, includesPatchComponent: Bool? = nil) {
        guard major >= 0, minor >= 0, patch >= 0 else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
        self.includesPatchComponent = includesPatchComponent ?? (patch != 0)
    }
    
    public init?(string: String) {
        let components = string.split(separator: ".").map(String.init)
        guard (2 ... 3).contains(components.count) else { return nil }
        
        let integers = components.compactMap { Int($0) }
        guard integers.count == components.count else { return nil }
        
        switch integers.count {
        case 2:
            self.init(major: integers[0], minor: integers[1], patch: 0, includesPatchComponent: false)
        case 3:
            self.init(major: integers[0], minor: integers[1], patch: integers[2], includesPatchComponent: true)
        default:
            return nil
        }
    }
    
    public var description: String {
        if !includesPatchComponent && patch == 0 {
            return "\(major).\(minor)"
        }
        
        return "\(major).\(minor).\(patch)"
    }
    
    public static func < (lhs: ProtocolVersion, rhs: ProtocolVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        
        return lhs.patch < rhs.patch
    }
}
