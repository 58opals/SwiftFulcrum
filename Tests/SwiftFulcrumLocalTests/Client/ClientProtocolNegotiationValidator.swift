// ClientProtocolNegotiationValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientProtocolNegotiationValidator {
    @Test("FulcrumNetworkClient rejects negotiated protocol outside supported range", .timeLimit(.minutes(1)))
    func rejectNegotiatedProtocolOutsideSupportedRange() async throws {
        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6"))

        let transport = TransportTestActor()
        let negotiation = try SwiftFulcrum.Client.Configuration.ProtocolNegotiation(
            minimumVersion: minimum,
            maximumVersion: maximum
        )
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: negotiation)

        let startTask = Task { try await client.start() }

        let versionRequest = await transport.dequeueOutgoing()
        let requestObject = try TransportTestActor.decodeJSONObject(from: versionRequest)
        guard let identifier = requestObject["id"] as? String else {
            Issue.record("Version request is missing an identifier")
            startTask.cancel()
            return
        }

        let unsupportedVersion = ["ElectrumX", "1.0"]
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: unsupportedVersion
        )
        await transport.enqueueIncoming(.data(payload))

        await #expect(throws: SwiftFulcrum.ProtocolVersion.Range.Error.unsupportedVersionRange) {
            try await startTask.value
        }
        #expect(await transport.connectionState == .disconnected)

        await client.stop()
    }
}
