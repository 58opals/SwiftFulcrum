import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ProtocolNegotiationConfigurationValidator {
    @Test("Provides sensible defaults")
    func provideSensibleDefaults() throws {
        let configuration = Fulcrum.Configuration()
        let negotiation = configuration.protocolNegotiation

        #expect(negotiation.clientName.hasPrefix("SwiftFulcrum/"))
        #expect(negotiation.min == ProtocolVersion(string: "1.4"))
        #expect(negotiation.max == ProtocolVersion(string: "1.6.0"))

        let supportedRange = negotiation.supportedRange
        #expect(supportedRange.contains(try #require(ProtocolVersion(string: "1.5"))))
    }
}
