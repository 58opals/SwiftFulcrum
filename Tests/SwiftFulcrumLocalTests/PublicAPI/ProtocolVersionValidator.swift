// ProtocolVersionValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolVersionValidator {
    @Test("Parses dotted versions")
    func parseDottedVersions() throws {
        let simple = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))
        #expect(simple.major == 1)
        #expect(simple.minor == 6)
        #expect(simple.patch == 0)
        #expect(simple.description == "1.6")

        let patched = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4.1"))
        #expect(patched.major == 1)
        #expect(patched.minor == 4)
        #expect(patched.patch == 1)
        #expect(patched.description == "1.4.1")
    }

    @Test(
        "Rejects malformed dotted versions",
        arguments: ["1", "1.2.3.4", "1..6", ".1.6", "1.6.", "1.a", "-1.0", "+1.0"]
    )
    func rejectMalformedVersions(_ version: String) {
        #expect(SwiftFulcrum.ProtocolVersion(string: version) == nil)
    }

    @Test("Decodes dotted version strings")
    func decodeDottedVersionStrings() throws {
        let simple = try JSONDecoder().decode(
            SwiftFulcrum.ProtocolVersion.self,
            from: Data(#""1.6""#.utf8)
        )
        #expect(simple.description == "1.6")

        let patched = try JSONDecoder().decode(
            SwiftFulcrum.ProtocolVersion.self,
            from: Data(#""1.6.0""#.utf8)
        )
        #expect(patched.description == "1.6.0")
    }

    @Test(
        "Rejects malformed decoded version strings",
        arguments: ["1", "1.6.", "1.a"]
    )
    func rejectMalformedDecodedVersionStrings(_ version: String) {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                SwiftFulcrum.ProtocolVersion.self,
                from: Data("\"\(version)\"".utf8)
            )
        }
    }

    @Test("Compares semantic ordering")
    func compareSemanticOrdering() throws {
        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let midpoint = try #require(SwiftFulcrum.ProtocolVersion(string: "1.5.2"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))

        #expect(minimum < midpoint)
        #expect(midpoint < maximum)
        #expect(maximum > minimum)
    }

    @Test("Treats implicit and explicit zero patch versions as equal")
    func treatImplicitAndExplicitZeroPatchVersionsAsEqual() throws {
        let implicitPatch = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))
        let explicitPatch = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))

        #expect(implicitPatch == explicitPatch)
        #expect(!(implicitPatch < explicitPatch))
        #expect(!(explicitPatch < implicitPatch))
    }
}
