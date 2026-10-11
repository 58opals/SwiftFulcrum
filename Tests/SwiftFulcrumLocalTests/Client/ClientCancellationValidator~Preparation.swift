// ClientCancellationValidator~Preparation.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    enum PreparationSharing: CaseIterable, Sendable {
        case soleCaller
        case cancelledOwner
        case cancelledWaiter
    }

    @Test(
        "Explicit cancellation interrupts startup without cancelling another caller",
        .timeLimit(.minutes(1)),
        arguments: [false, true], PreparationSharing.allCases
    )
    func explicitCancellationInterruptsPreparation(
        subscription: Bool,
        sharing: PreparationSharing
    ) async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()
        let completion = CancellationCompletionState()
        var healthyStart: Task<Void, Swift.Error>?

        if sharing == .cancelledWaiter {
            healthyStart = Task { try await client.start() }
            let ownerSentVersion = await waitUntil(timeout: .seconds(2)) {
                await transport.sentMessages.count == 1
            }
            if !ownerSentVersion {
                healthyStart?.cancel()
                await client.stop()
                _ = try? await healthyStart?.value
            }
            try #require(ownerSentVersion)
        }
        let call = Task {
            do {
                if subscription {
                    _ = try await client.subscribe(
                        SwiftFulcrum.API.blockchain.headers.subscribe,
                        options: .init(cancellation: cancellation)
                    )
                } else {
                    _ = try await client.request(
                        SwiftFulcrum.API.blockchain.headers.tip,
                        options: .init(cancellation: cancellation)
                    )
                }
                Issue.record("A cancelled call must not complete successfully.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        do {
            let sentVersion = await waitUntil(timeout: .seconds(2)) {
                await transport.sentMessages.count == 1
            }
            try #require(sentVersion)
            let version = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
            #expect(version["method"] as? String == "server.version")

            if sharing == .cancelledOwner {
                healthyStart = Task { try await client.start() }
            }
            if sharing != .soleCaller {
                let bothWaiting = await waitUntil(timeout: .seconds(2)) {
                    guard let generation = await client.startTaskGenerationIdentifierForTesting else { return false }
                    return await client.makeStartTaskWaiterCountForTesting(generationIdentifier: generation) == 2
                }
                try #require(bothWaiting)
            }

            // No version response or call timeout: only the explicit token can release this wait.
            await cancellation.cancel()
            let cancelledBeforeNegotiationCompleted = await waitUntil(timeout: .seconds(2)) {
                await completion.isCompleted
            }
            #expect(cancelledBeforeNegotiationCompleted)
            if !cancelledBeforeNegotiationCompleted {
                // Keep a broken implementation from leaving this regression suspended forever.
                call.cancel()
            }
            await call.value
            if cancelledBeforeNegotiationCompleted {
                #expect(await completion.recordedError == .client(.cancelled))
            }

            if let healthyStart {
                let versionPayload = try TransportTestActor.encodeResponsePayload(
                    identifier: extractRequestIdentifier(from: version),
                    result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
                )
                await transport.enqueueIncoming(.data(versionPayload))
                let sentFeatures = await waitUntil(timeout: .seconds(2)) {
                    await transport.sentMessages.count == 2
                }
                try #require(sentFeatures)
                let features = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
                #expect(features["method"] as? String == "server.features")
                let featuresPayload = try TransportTestActor.encodeResponsePayload(
                    identifier: extractRequestIdentifier(from: features),
                    result: [
                        "genesis_hash": String(repeating: "0", count: 64),
                        "hash_function": "sha256",
                        "server_version": "SwiftFulcrum.Client 2.0",
                        "protocol_max": "1.6.0",
                        "protocol_min": "1.4.0"
                    ]
                )
                await transport.enqueueIncoming(.data(featuresPayload))
                try await healthyStart.value
                #expect(await client.isRunning)
            }

            let methods = try await transport.sentMessages.map {
                try TransportTestActor.decodeJSONObject(from: $0)["method"] as? String
            }
            #expect(methods.allSatisfy { $0 == "server.version" || $0 == "server.features" })
            #expect(await client.makeActiveSubscriptionCount() == 0)
            await client.stop()
        } catch {
            call.cancel()
            healthyStart?.cancel()
            await client.stop()
            await call.value
            _ = try? await healthyStart?.value
            throw error
        }
    }
}
