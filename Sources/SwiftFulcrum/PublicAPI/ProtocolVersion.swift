// ProtocolVersion.swift

import Foundation

extension SwiftFulcrum {
    public struct ProtocolVersion: Comparable, CustomStringConvertible, Decodable, Sendable {
        public let major: Int
        public let minor: Int
        public let patch: Int
        private let isPatchComponentIncluded: Bool

        public init?(major: Int, minor: Int) {
            guard major >= 0, minor >= 0 else { return nil }
            self.major = major
            self.minor = minor
            self.patch = 0
            self.isPatchComponentIncluded = false
        }

        public init?(major: Int, minor: Int, patch: Int, isPatchComponentIncluded: Bool? = nil) {
            guard major >= 0, minor >= 0, patch >= 0 else { return nil }
            self.major = major
            self.minor = minor
            self.patch = patch
            self.isPatchComponentIncluded = isPatchComponentIncluded ?? true
        }

        public init?(string: String) {
            let components = string.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard (2 ... 3).contains(components.count) else { return nil }

            let integers = components.compactMap(Self.parseComponent)
            guard integers.count == components.count else { return nil }

            switch integers.count {
            case 2:
                self.init(major: integers[0], minor: integers[1])
            case 3:
                self.init(major: integers[0], minor: integers[1], patch: integers[2], isPatchComponentIncluded: true)
            default:
                return nil
            }
        }

        private static func parseComponent(_ component: String) -> Int? {
            guard !component.isEmpty else { return nil }
            guard component.utf8.allSatisfy({ (48 ... 57).contains($0) }) else { return nil }
            return Int(component)
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            guard let version = Self(string: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Protocol version must be a dotted version string."
                )
            }

            self = version
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

        public static func == (lhs: SwiftFulcrum.ProtocolVersion, rhs: SwiftFulcrum.ProtocolVersion) -> Bool {
            lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
        }
    }
}
