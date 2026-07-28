// FulcrumClientLifecycleValidator~ReconnectReadinessBudget.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("request(timeout:) uses one end-to-end budget while waiting for reconnect readiness", .timeLimit(.minutes(1)))
    func useSingleRequestTimeoutBudgetWhileWaitingForReconnectReadiness() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))
        let timeout: Duration = .milliseconds(200)

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
        let baselineOutgoingCount = await transport.sentMessages.count

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: requestMethod,
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("request() should time out after spending the single reconnect-readiness budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        try? await Task.sleep(for: .milliseconds(120))
        await transport.configureOutgoingSendDelay(.milliseconds(100))

        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))

        try await reconnectTask.value

        let error = await requestTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)

        await fulcrum.stop()
    }
}
