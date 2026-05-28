// ProtocolVersionRangeValidator.swift

import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolVersionRangeValidator {
    @Test("Validates supported range")
    func validateSupportedRange() throws {
        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))
        #expect(SwiftFulcrum.ProtocolVersion.Range(min: maximum, max: minimum) == nil)

        let range = try #require(SwiftFulcrum.ProtocolVersion.Range(min: minimum, max: maximum))
        #expect(range.contains(try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))))
        #expect(!range.contains(try #require(SwiftFulcrum.ProtocolVersion(string: "1.7"))))
    }

    @Test("Chooses highest overlapping version")
    func chooseHighestOverlap() throws {
        let versionOnePointFour = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let versionOnePointFive = try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))
        let versionOnePointFivePointThree = try #require(SwiftFulcrum.ProtocolVersion(string: "1.5.3"))
        let versionOnePointSix = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))

        let clientRange = try #require(SwiftFulcrum.ProtocolVersion.Range(
            min: versionOnePointFour,
            max: versionOnePointSix
        ))
        let serverRange = try #require(SwiftFulcrum.ProtocolVersion.Range(
            min: versionOnePointFive,
            max: versionOnePointFivePointThree
        ))

        let negotiated = try clientRange.chooseNegotiatedVersion(with: serverRange)
        #expect(negotiated == SwiftFulcrum.ProtocolVersion(string: "1.5.3"))
    }

    @Test("Throws when ranges do not overlap")
    func throwWhenRangesDoNotOverlap() throws {
        let versionOnePointTwo = try #require(SwiftFulcrum.ProtocolVersion(string: "1.2"))
        let versionOnePointThree = try #require(SwiftFulcrum.ProtocolVersion(string: "1.3"))
        let versionOnePointFour = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let versionOnePointFive = try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))

        let clientRange = try #require(SwiftFulcrum.ProtocolVersion.Range(
            min: versionOnePointTwo,
            max: versionOnePointThree
        ))
        let serverRange = try #require(SwiftFulcrum.ProtocolVersion.Range(
            min: versionOnePointFour,
            max: versionOnePointFive
        ))

        #expect(throws: SwiftFulcrum.ProtocolVersion.Range.Error.unsupportedVersionRange) {
            _ = try clientRange.chooseNegotiatedVersion(with: serverRange)
        }
    }
}
