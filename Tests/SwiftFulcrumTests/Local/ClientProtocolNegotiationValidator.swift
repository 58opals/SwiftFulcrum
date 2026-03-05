import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientProtocolNegotiationValidator {
    @Test("FulcrumNetworkClient rejects negotiated protocol outside supported range", .timeLimit(.minutes(1)))
    func rejectNegotiatedProtocolOutsideSupportedRange() async throws {
        guard
            let minimum = SwiftFulcrum.ProtocolVersion(string: "1.6"),
            let maximum = SwiftFulcrum.ProtocolVersion(string: "1.6")
        else {
            Issue.record("Failed to build protocol versions for negotiation test")
            return
        }

        let transport = TransportTestActor()
        let negotiation = SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel(min: minimum, max: maximum)
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

        do {
            try await startTask.value
            Issue.record("FulcrumNetworkClient.start() should fail for unsupported negotiated protocol")
        } catch let error as SwiftFulcrum.ProtocolVersion.Range.Error {
            #expect(error == .unsupportedVersionRange)
            #expect(await transport.connectionState == .disconnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        await client.stop()
    }
}
