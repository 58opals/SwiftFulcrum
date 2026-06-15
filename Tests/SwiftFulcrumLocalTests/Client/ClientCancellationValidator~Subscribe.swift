// ClientCancellationValidator~Subscribe.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test("subscribe(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func subscribeTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))

        let baselineOutgoingCount = await transport.sentMessages.count

        let subscribeTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        let error = await subscribeTask.value
        #expect(isTimeoutError(error))

        try? await Task.sleep(for: .milliseconds(1_200))
        let finalOutgoingCount = await transport.sentMessages.count
        #expect(finalOutgoingCount == baselineOutgoingCount)

        #expect(await fulcrum.makeActiveSubscriptionCount() == 0)

        await fulcrum.stop()
    }

    @Test("subscribe(timeout:) uses one end-to-end budget when starting from idle", .timeLimit(.minutes(1)))
    func subscribeTimeoutUsesSingleBudgetWhenStartingFromIdle() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(120))

        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let timeout: Duration = .milliseconds(200)

        let subscribeTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("subscribe() should time out after spending the single end-to-end budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
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

        let error = await subscribeTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == 2)
        #expect(await client.makeActiveSubscriptionStates().isEmpty)
        #expect(await client.makeActiveSubscriptionCount() == 0)

        await client.stop()
    }

    @Test("subscribe(task cancellation) does not emit a late request", .timeLimit(.minutes(1)))
    func subscribeTaskCancellationDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendPaused(true)

        let baselineOutgoingCount = await transport.sentMessages.count
        let completion = CancellationCompletionState()

        let subscribeTask = Task {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("subscribe() should throw cancelled when the calling task is cancelled.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseSubscribeSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseSubscribeSend)

        subscribeTask.cancel()
        await transport.configureOutgoingSendPaused(false)

        let didComplete = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        #expect(didComplete)

        if didComplete {
            #expect(isCancelledError(await completion.recordedError ?? .client(.unknown(nil))))
        }

        try? await Task.sleep(for: .milliseconds(150))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)
        #expect(await fulcrum.makeActiveSubscriptionCount() == 0)

        await fulcrum.stop()
    }
}
