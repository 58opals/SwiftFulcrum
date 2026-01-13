import Foundation
import Testing
@testable import SwiftFulcrum

struct ClientProtocolNegotiationTests {
    @Test("Client rejects negotiated protocol outside supported range", .timeLimit(.minutes(1)))
    func rejectUnsupportedNegotiatedProtocol() async throws {
        guard
            let minimum = ProtocolVersion(string: "1.6"),
            let maximum = ProtocolVersion(string: "1.6")
        else {
            Issue.record("Failed to build protocol versions for negotiation test")
            return
        }
        
        let transport = TransportStub()
        let negotiation = Fulcrum.Configuration.ProtocolNegotiation(min: minimum, max: maximum)
        let client = Client(transport: transport, protocolNegotiation: negotiation)
        
        let startTask = Task { try await client.start() }
        
        let versionRequest = await transport.nextOutgoing()
        let requestObject = try makeJSONObject(from: versionRequest)
        guard let identifier = requestObject["id"] as? String else {
            Issue.record("Version request is missing an identifier")
            startTask.cancel()
            return
        }
        
        let unsupportedVersion = ["ElectrumX", "1.0"]
        let payload = try makeResponsePayload(id: identifier, result: unsupportedVersion)
        await transport.enqueueIncoming(.data(payload))
        
        do {
            try await startTask.value
            Issue.record("Client.start() should fail for unsupported negotiated protocol")
        } catch let error as ProtocolVersion.Range.Error {
            #expect(error == .unsupportedVersionRange)
            #expect(await transport.connectionState == .disconnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        await client.stop()
    }
}
