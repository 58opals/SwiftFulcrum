// ProtocolNegotiationConfigurationValidator.swift

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
        #expect(negotiation.minimumVersion == SwiftFulcrum.ProtocolVersion(string: "1.4"))
        #expect(negotiation.maximumVersion == SwiftFulcrum.ProtocolVersion(string: "1.6.0"))

        let supportedRange = negotiation.supportedRange
        #expect(supportedRange.contains(try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))))
    }
    
    @Test("Invalid protocol negotiation ranges throw recoverable errors")
    func throwForInvalidRanges() throws {
        let minimumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        let maximumVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4.0"))
        
        do {
            _ = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation(
                minimumVersion: minimumVersion,
                maximumVersion: maximumVersion
            )
            Issue.record("Expected protocol negotiation initialization to throw for an invalid range")
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
            _ = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument(
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
        let negotiation = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation(
            minimumVersion: minimumVersion,
            maximumVersion: maximumVersion
        )
        
        let rangeArgument = negotiation.makeArgument()
        let rangeObject = try JSONDecoder().decode([String].self, from: JSONEncoder().encode(rangeArgument))
        #expect(rangeObject == ["1.4", "1.6.0"])
        
        let singleArgument = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument(
            minimumVersion: minimumVersion,
            maximumVersion: minimumVersion
        )
        let singleObject = try JSONDecoder().decode(String.self, from: JSONEncoder().encode(singleArgument))
        #expect(singleObject == "1.4")
    }

    @Test("Explicit zero patch versions stay explicit in protocol negotiation")
    func preserveExplicitZeroPatchVersions() throws {
        let exactVersion = try #require(
            SwiftFulcrum.ProtocolVersion(major: 1, minor: 6, patch: 0)
        )
        #expect(exactVersion.description == "1.6.0")

        let exactArgument = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument(
            minimumVersion: exactVersion,
            maximumVersion: exactVersion
        )
        let encoded = try JSONDecoder().decode(String.self, from: JSONEncoder().encode(exactArgument))
        #expect(encoded == "1.6.0")
    }
}
