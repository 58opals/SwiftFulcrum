import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolVersionRangeValidator {
    @Test("Validates supported range")
    func validateSupportedRange() throws {
        let minimum = try #require(ProtocolVersionModel(string: "1.4"))
        let maximum = try #require(ProtocolVersionModel(string: "1.6"))
        #expect(ProtocolVersionModel.RangeModel(min: maximum, max: minimum) == nil)

        let range = try #require(ProtocolVersionModel.RangeModel(min: minimum, max: maximum))
        #expect(range.contains(try #require(ProtocolVersionModel(string: "1.5"))))
        #expect(!range.contains(try #require(ProtocolVersionModel(string: "1.7"))))
    }

    @Test("Chooses highest overlapping version")
    func chooseHighestOverlap() throws {
        let versionOnePointFour = try #require(ProtocolVersionModel(string: "1.4"))
        let versionOnePointFive = try #require(ProtocolVersionModel(string: "1.5"))
        let versionOnePointFivePointThree = try #require(ProtocolVersionModel(string: "1.5.3"))
        let versionOnePointSix = try #require(ProtocolVersionModel(string: "1.6"))

        let clientRange = try #require(ProtocolVersionModel.RangeModel(
            min: versionOnePointFour,
            max: versionOnePointSix
        ))
        let serverRange = try #require(ProtocolVersionModel.RangeModel(
            min: versionOnePointFive,
            max: versionOnePointFivePointThree
        ))

        let negotiated = try clientRange.chooseNegotiatedVersion(with: serverRange)
        #expect(negotiated == ProtocolVersionModel(string: "1.5.3"))
    }

    @Test("Throws when ranges do not overlap")
    func throwWhenRangesDoNotOverlap() throws {
        let versionOnePointTwo = try #require(ProtocolVersionModel(string: "1.2"))
        let versionOnePointThree = try #require(ProtocolVersionModel(string: "1.3"))
        let versionOnePointFour = try #require(ProtocolVersionModel(string: "1.4"))
        let versionOnePointFive = try #require(ProtocolVersionModel(string: "1.5"))

        let clientRange = try #require(ProtocolVersionModel.RangeModel(
            min: versionOnePointTwo,
            max: versionOnePointThree
        ))
        let serverRange = try #require(ProtocolVersionModel.RangeModel(
            min: versionOnePointFour,
            max: versionOnePointFive
        ))

        do {
            _ = try clientRange.chooseNegotiatedVersion(with: serverRange)
            Issue.record("Expected negotiation to fail when no overlap exists")
        } catch let error as ProtocolVersionModel.RangeModel.Error {
            #expect(error == .unsupportedVersionRange)
        }
    }
}
