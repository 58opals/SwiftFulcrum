import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolNegotiationConfigurationValidator {
    @Test("Provides sensible defaults")
    func provideSensibleDefaults() throws {
        let configuration = SwiftFulcrum.Client.Configuration()
        let negotiation = configuration.protocolNegotiation

        #expect(negotiation.clientName.hasPrefix("SwiftFulcrum/"))
        #expect(negotiation.min == SwiftFulcrum.ProtocolVersion(string: "1.4"))
        #expect(negotiation.max == SwiftFulcrum.ProtocolVersion(string: "1.6.0"))

        let supportedRange = try negotiation.supportedRange
        #expect(supportedRange.contains(try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))))
    }
    
    @Test("Invalid protocol negotiation ranges throw recoverable errors")
    func throwForInvalidRanges() throws {
        let minimumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        let maximumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4.0"))
        
        let negotiation = SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel(
            min: minimumVersion,
            max: maximumVersion
        )
        
        do {
            _ = try negotiation.supportedRange
            Issue.record("Expected supportedRange to throw for an invalid range")
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(
                error == .client(
                    .invalidProtocolNegotiationRange(
                        minimumVersion: minimumVersion,
                        maximumVersion: maximumVersion
                    )
                )
            )
        }
        
        do {
            _ = try negotiation.argument
            Issue.record("Expected argument to throw for an invalid range")
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(
                error == .client(
                    .invalidProtocolNegotiationRange(
                        minimumVersion: minimumVersion,
                        maximumVersion: maximumVersion
                    )
                )
            )
        }
        
        do {
            _ = try SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel.Argument(
                minimumVersion: minimumVersion,
                maximumVersion: maximumVersion
            )
            Issue.record("Expected argument initializer to throw for an invalid range")
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(
                error == .client(
                    .invalidProtocolNegotiationRange(
                        minimumVersion: minimumVersion,
                        maximumVersion: maximumVersion
                    )
                )
            )
        }
    }
    
    @Test("Protocol negotiation argument encodes valid ranges")
    func encodeValidRangeArguments() throws {
        let minimumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let maximumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        
        let rangeArgument = try SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel.Argument(
            minimumVersion: minimumVersion,
            maximumVersion: maximumVersion
        )
        let rangeObject = try JSONDecoder().decode([String].self, from: JSONEncoder().encode(rangeArgument))
        #expect(rangeObject == ["1.4", "1.6.0"])
        
        let singleArgument = try SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel.Argument(
            minimumVersion: minimumVersion,
            maximumVersion: minimumVersion
        )
        let singleObject = try JSONDecoder().decode(String.self, from: JSONEncoder().encode(singleArgument))
        #expect(singleObject == "1.4")
    }
}
