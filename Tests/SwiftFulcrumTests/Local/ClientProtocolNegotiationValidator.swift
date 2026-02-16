import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientProtocolNegotiationValidator {
    @Test("Client rejects negotiated protocol outside supported range", .timeLimit(.minutes(1)))
    func rejectNegotiatedProtocolOutsideSupportedRange() async throws {
        guard
            let minimum = ProtocolVersionModel(string: "1.6"),
            let maximum = ProtocolVersionModel(string: "1.6")
        else {
            Issue.record("Failed to build protocol versions for negotiation test")
            return
        }

        let transport = TransportTestActor()
        let negotiation = FulcrumClient.Configuration.ProtocolNegotiationModel(min: minimum, max: maximum)
        let client = Client(transport: transport, protocolNegotiation: negotiation)

        let startTask = Task { try await client.start() }

        let versionRequest = await transport.dequeueOutgoing()
        let requestObject = try TransportTestActor.decodeJSONObject(from: versionRequest)
        guard let identifier = requestObject["id"] as? String else {
            Issue.record("VersionModel request is missing an identifier")
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
            Issue.record("Client.start() should fail for unsupported negotiated protocol")
        } catch let error as ProtocolVersionModel.RangeModel.Error {
            #expect(error == .unsupportedVersionRange)
            #expect(await transport.connectionState == .disconnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        await client.stop()
    }
}
