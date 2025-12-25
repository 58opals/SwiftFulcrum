import Testing
@testable import SwiftFulcrum

struct ProtocolVersionTests {
    @Test("Parses dotted versions")
    func parsesDottedVersions() throws {
        let simple = try #require(ProtocolVersion(string: "1.6"))
        #expect(simple.major == 1)
        #expect(simple.minor == 6)
        #expect(simple.patch == 0)
        #expect(simple.description == "1.6")
        
        let patched = try #require(ProtocolVersion(string: "1.4.1"))
        #expect(patched.major == 1)
        #expect(patched.minor == 4)
        #expect(patched.patch == 1)
        #expect(patched.description == "1.4.1")
    }
    
    @Test("Rejects malformed dotted versions")
    func rejectsMalformedVersions() {
        #expect(ProtocolVersion(string: "1") == nil)
        #expect(ProtocolVersion(string: "1.2.3.4") == nil)
        #expect(ProtocolVersion(string: "1.a") == nil)
        #expect(ProtocolVersion(string: "-1.0") == nil)
    }
    
    @Test("Compares semantic ordering")
    func comparesSemanticOrdering() throws {
        let minimum = try #require(ProtocolVersion(string: "1.4"))
        let midpoint = try #require(ProtocolVersion(string: "1.5.2"))
        let maximum = try #require(ProtocolVersion(string: "1.6.0"))
        
        #expect(minimum < midpoint)
        #expect(midpoint < maximum)
        #expect(maximum > minimum)
    }
}

struct ProtocolVersionRangeTests {
    @Test("Validates supported range")
    func validatesSupportedRange() throws {
        let minimum = try #require(ProtocolVersion(string: "1.4"))
        let maximum = try #require(ProtocolVersion(string: "1.6"))
        #expect(ProtocolVersion.Range(min: maximum, max: minimum) == nil)
        
        let range = try #require(ProtocolVersion.Range(min: minimum, max: maximum))
        #expect(range.contains(try #require(ProtocolVersion(string: "1.5"))))
        #expect(!range.contains(try #require(ProtocolVersion(string: "1.7"))))
    }
    
    @Test("Chooses highest overlapping version")
    func choosesHighestOverlap() throws {
        let v1point4 = try #require(ProtocolVersion(string: "1.4"))
        let v1point5 = try #require(ProtocolVersion(string: "1.5"))
        let v1point53 = try #require(ProtocolVersion(string: "1.5.3"))
        let v1point6 = try #require(ProtocolVersion(string: "1.6"))
        
        let clientRange = try #require(ProtocolVersion.Range(
            min: v1point4,
            max: v1point6
        ))
        let serverRange = try #require(ProtocolVersion.Range(
            min: v1point5,
            max: v1point53
        ))
        
        let negotiated = try clientRange.chooseNegotiatedVersion(with: serverRange)
        #expect(negotiated == ProtocolVersion(string: "1.5.3"))
    }
    
    @Test("Throws when ranges do not overlap")
    func throwsWhenRangesDoNotOverlap() throws {
        let v1point2 = try #require(ProtocolVersion(string: "1.2"))
        let v1point3 = try #require(ProtocolVersion(string: "1.3"))
        let v1point4 = try #require(ProtocolVersion(string: "1.4"))
        let v1point5 = try #require(ProtocolVersion(string: "1.5"))
        
        let clientRange = try #require(ProtocolVersion.Range(
            min: v1point2,
            max: v1point3
        ))
        let serverRange = try #require(ProtocolVersion.Range(
            min: v1point4,
            max: v1point5
        ))
        
        do {
            _ = try clientRange.chooseNegotiatedVersion(with: serverRange)
            Issue.record("Expected negotiation to fail when no overlap exists")
        } catch let error as ProtocolVersion.Range.Error {
            #expect(error == .unsupportedVersionRange)
        }
    }
}

struct ProtocolNegotiationConfigurationTests {
    @Test("Provides sensible defaults")
    func providesSensibleDefaults() throws {
        let configuration = Fulcrum.Configuration()
        let negotiation = configuration.protocolNegotiation
        
        #expect(negotiation.clientName.hasPrefix("SwiftFulcrum/"))
        #expect(negotiation.min == ProtocolVersion(string: "1.4"))
        #expect(negotiation.max == ProtocolVersion(string: "1.6.0"))
        
        let supportedRange = negotiation.supportedRange
        #expect(supportedRange.contains(try #require(ProtocolVersion(string: "1.5"))))
    }
}
