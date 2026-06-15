// FulcrumClientLifecycleValidator~ReconnectReadinessTimeout.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("request waits when automatic reconnect is connected before recovery", .timeLimit(.minutes(1)))
    func requestWaitsWhenAutomaticReconnectIsConnectedBeforeRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let requestMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        await transport.configureConnectionState(.reconnecting)
        try? await Task.sleep(for: .milliseconds(250))
        await transport.configureConnectionState(.connected)

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let didSendRequestEarly = await waitUntil(timeout: .milliseconds(150)) {
            let requestCount = (try? await countSentMethodOccurrences(
                requestMethod.path,
                transport: transport
            )) ?? 0
            return requestCount > 0
        }
        #expect(didSendRequestEarly == false)

        guard !didSendRequestEarly else {
            requestTask.cancel()
            await fulcrum.stop()
            return
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

        let request = try await dequeueNextRequestObject(
            matching: requestMethod.path,
            transport: transport
        )
        let requestIdentifier = try extractRequestIdentifier(from: request)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: ["height": 936_002, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        let result = try await requestTask.value
        #expect(result.height == 936_002)
        #expect(result.hex == String(repeating: "a", count: 160))

        await fulcrum.stop()
    }

    @Test("automatic reconnect negotiation failure disconnects transport", .timeLimit(.minutes(1)))
    func automaticReconnectNegotiationFailureDisconnectsTransport() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        await transport.configureConnectionState(.reconnecting)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.3.0"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let didDisconnect = await waitUntil(timeout: .milliseconds(250)) {
            await transport.connectionState == .disconnected
        }
        #expect(didDisconnect)

        await fulcrum.stop()
    }

    @Test("request(timeout:) uses one end-to-end budget while waiting for reconnect readiness", .timeLimit(.minutes(1)))
    func requestTimeoutUsesSingleBudgetWhileWaitingForReconnectReadiness() async throws {
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
