// ClientCancellationValidator~SharedStart.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test("start task cancellation does not hang while connecting", .timeLimit(.minutes(1)))
    func startTaskCancellationDoesNotHangWhileConnecting() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.seconds(5))
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let completion = CancellationCompletionState()

        let startTask = Task {
            do {
                try await client.start()
                Issue.record("start() should throw cancelled when the calling task is cancelled.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch is CancellationError {
                await completion.finish(with: .client(.cancelled))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        try? await Task.sleep(for: .milliseconds(50))
        startTask.cancel()

        let didComplete = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        #expect(didComplete)

        if didComplete {
            #expect(isCancelledError(await completion.recordedError ?? .client(.unknown(nil))))
        }

        #expect(await transport.connectionState == .idle)
    }

    @Test("cancelled shared start waiter does not cancel startup owner", .timeLimit(.minutes(1)))
    func cancelledSharedStartWaiterDoesNotCancelStartupOwner() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(100))
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let waiterCompletion = CancellationCompletionState()

        let ownerStartTask = Task {
            try await client.start()
        }

        try? await Task.sleep(for: .milliseconds(10))
        let waiterStartTask = Task {
            do {
                try await client.start()
                Issue.record("Cancelled shared start waiter should not complete successfully.")
                await waiterCompletion.finish(with: .client(.unknown(nil)))
            } catch is CancellationError {
                await waiterCompletion.finish(with: .client(.cancelled))
            } catch let error as SwiftFulcrum.Client.Error {
                await waiterCompletion.finish(with: error)
            } catch {
                await waiterCompletion.finish(with: .client(.unknown(error)))
            }
        }

        try? await Task.sleep(for: .milliseconds(10))
        waiterStartTask.cancel()

        let didCancelWaiter = await waitUntil(timeout: .seconds(2)) {
            await waiterCompletion.isCompleted
        }
        #expect(didCancelWaiter)

        if didCancelWaiter {
            #expect(isCancelledError(await waiterCompletion.recordedError ?? .client(.unknown(nil))))
        }

        let didSendNegotiationRequest = await waitUntil(timeout: .seconds(2)) {
            await !transport.sentMessages.isEmpty
        }
        #expect(didSendNegotiationRequest)
        guard didSendNegotiationRequest else {
            ownerStartTask.cancel()
            _ = try? await ownerStartTask.value
            return
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
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

        try await ownerStartTask.value
        await client.stop()
    }

    @Test("cancelled shared start owner does not cancel waiting start", .timeLimit(.minutes(1)))
    func cancelledSharedStartOwnerDoesNotCancelWaitingStart() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(100))
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let ownerCompletion = CancellationCompletionState()

        let ownerStartTask = Task {
            do {
                try await client.start()
                Issue.record("Cancelled shared start owner should not complete successfully.")
                await ownerCompletion.finish(with: .client(.unknown(nil)))
            } catch is CancellationError {
                await ownerCompletion.finish(with: .client(.cancelled))
            } catch let error as SwiftFulcrum.Client.Error {
                await ownerCompletion.finish(with: error)
            } catch {
                await ownerCompletion.finish(with: .client(.unknown(error)))
            }
        }

        try? await Task.sleep(for: .milliseconds(10))
        let waiterStartTask = Task {
            try await client.start()
        }

        try? await Task.sleep(for: .milliseconds(10))
        ownerStartTask.cancel()

        let didCancelOwner = await waitUntil(timeout: .seconds(2)) {
            await ownerCompletion.isCompleted
        }
        #expect(didCancelOwner)

        if didCancelOwner {
            #expect(isCancelledError(await ownerCompletion.recordedError ?? .client(.unknown(nil))))
        }

        let didSendNegotiationRequest = await waitUntil(timeout: .seconds(2)) {
            await !transport.sentMessages.isEmpty
        }
        #expect(didSendNegotiationRequest)
        guard didSendNegotiationRequest else {
            waiterStartTask.cancel()
            _ = try? await waiterStartTask.value
            return
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
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

        try await waiterStartTask.value
        await client.stop()
    }
}
