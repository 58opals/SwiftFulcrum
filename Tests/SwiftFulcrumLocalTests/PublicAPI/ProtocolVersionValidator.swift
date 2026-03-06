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

    @Test("Rejects malformed dotted versions")
    func rejectMalformedVersions() {
        #expect(SwiftFulcrum.ProtocolVersion(string: "1") == nil)
        #expect(SwiftFulcrum.ProtocolVersion(string: "1.2.3.4") == nil)
        #expect(SwiftFulcrum.ProtocolVersion(string: "1.a") == nil)
        #expect(SwiftFulcrum.ProtocolVersion(string: "-1.0") == nil)
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
}
