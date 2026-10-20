// ClientCancellationValidator~SendAuthorization.swift

import Foundation
import Synchronization
import Testing
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    enum AuthorizationWait: CaseIterable, Sendable {
        case startup, reconnect, transport
    }

    enum AuthorizationTime: CaseIterable, Sendable {
        case timely, equality, expired, notANumber, infinite

        var value: Double {
            switch self {
            case .timely: 199
            case .equality: 200
            case .expired: 201
            case .notANumber: .nan
            case .infinite: .infinity
            }
        }
    }

    @Test("Outbound authorization is evaluated after preparation and transport waits",
          .timeLimit(.minutes(1)), arguments: AuthorizationWait.allCases, AuthorizationTime.allCases)
    func authorizeBroadcastAfterWait(_ wait: AuthorizationWait, _ time: AuthorizationTime) async throws {
        let client: SwiftFulcrum.Client
        let transport: TransportTestActor
        if wait == .startup {
            transport = TransportTestActor()
            client = await SwiftFulcrum.Client(client: FulcrumNetworkClient(
                transport: transport, protocolNegotiation: .init()))
        } else {
            (client, transport) = try await makeStartedFulcrum()
        }
        let clock = AuthorizationClock()
        let authorization = SwiftFulcrum.Client.Call.SendAuthorization {
            clock.isAuthorized(before: 200)
        }
        let completion = BroadcastCompletion()
        let reconnectTask = wait == .reconnect ? Task { try await client.reconnect() } : nil
        let reconnectVersion: [String: Any]?
        if wait == .reconnect {
            // Establish the reconnect wait before starting the guarded caller.
            reconnectVersion = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
            // This synthetic transport leaves reconnect in .reconnecting until the test
            // supplies the successful handshake transition, as the lifecycle fixtures do.
            await transport.configureConnectionState(.connected)
        } else {
            reconnectVersion = nil
        }
        if wait == .transport { await transport.configureOutgoingSendPaused(true) }

        let call = Task {
            do {
                let response = try await client.request(
                    SwiftFulcrum.API.blockchain.transaction.broadcast(rawTransaction: "010203"),
                    options: .init(timeout: .seconds(30), sendAuthorization: authorization))
                await completion.finish(.success(response.transactionHash))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(.failure(error))
            } catch {
                await completion.finish(.failure(.client(.unknown(error))))
            }
        }

        do {
            if wait == .transport {
                let paused = await waitUntil(timeout: .seconds(2)) {
                    await transport.makePendingOutgoingSendCount() == 1
                }
                try #require(paused)
                #expect(clock.checkCount == 0)
                clock.set(time.value)
                await transport.configureOutgoingSendPaused(false)
            } else {
                // Both the idle start and reconnect remain suspended on their features response.
                let version: [String: Any]
                if let reconnectVersion { version = reconnectVersion }
                else { version = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing()) }
                #expect(version["method"] as? String == "server.version")
                await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
                    identifier: extractRequestIdentifier(from: version), result: ["test", "1.5.3"])))
                let features = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
                #expect(features["method"] as? String == "server.features")
                #expect(clock.checkCount == 0)
                clock.set(time.value)
                await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
                    identifier: extractRequestIdentifier(from: features), result: [
                        "genesis_hash": String(repeating: "0", count: 64), "hash_function": "sha256",
                        "server_version": "test", "protocol_max": "1.6.0", "protocol_min": "1.4.0"])))
                try await reconnectTask?.value
            }

            // Answer an unexpected submission too, so a broken guard fails without hanging.
            let settled = await waitUntil(timeout: .seconds(2)) {
                if await completion.result != nil { return true }
                return await self.broadcasts(on: transport).isEmpty == false
            }
            try #require(settled)
            let submitted = await broadcasts(on: transport)
            for request in submitted {
                #expect(request["params"] as? [String] == ["010203"])
                await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
                    identifier: extractRequestIdentifier(from: request), result: String(repeating: "ab", count: 32))))
            }
            await call.value
            #expect(clock.checkCount == 1)
            let result = await completion.result
            if time == .timely {
                #expect(submitted.count == 1)
                #expect(result == .success(Data(repeating: 0xab, count: 32)))
            } else {
                #expect(submitted.isEmpty)
                #expect(result == .failure(.client(.sendNotAuthorized)))
            }
            #expect(await client.makeInflightUnaryCallCount() == 0)
            await client.stop()
        } catch {
            call.cancel()
            reconnectTask?.cancel()
            await transport.configureOutgoingSendPaused(false)
            await client.stop()
            await call.value
            _ = try? await reconnectTask?.value
            throw error
        }
    }

    @Test("Authorization applies to handoff and is not reevaluated after submission", .timeLimit(.minutes(1)))
    func preserveAlreadySubmittedBroadcastAfterAuthorizationExpires() async throws {
        let (client, transport) = try await makeStartedFulcrum()
        let clock = AuthorizationClock()
        await transport.pauseNextSendCompletion(method: "blockchain.transaction.broadcast")
        let call = Task {
            try await client.request(SwiftFulcrum.API.blockchain.transaction.broadcast(rawTransaction: "010203"),
                options: .init(timeout: .seconds(30), sendAuthorization: .init {
                    clock.isAuthorized(before: 200)
                }))
        }
        let request = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(request["method"] as? String == "blockchain.transaction.broadcast")
        let completionPaused = await waitUntil(timeout: .seconds(2)) {
            await transport.pausedSendCompletionContinuations.count == 1
        }
        if !completionPaused {
            call.cancel()
            await transport.resumeSendCompletion()
            await client.stop()
            _ = try? await call.value
        }
        try #require(completionPaused)
        clock.set(200)
        await transport.enqueueIncoming(.data(try TransportTestActor.encodeResponsePayload(
            identifier: extractRequestIdentifier(from: request), result: String(repeating: "ab", count: 32))))
        await transport.resumeSendCompletion()
        let response = try await call.value
        #expect(response.transactionHash == Data(repeating: 0xab, count: 32))
        #expect(await broadcasts(on: transport).count == 1)
        #expect(clock.checkCount == 1)
        await client.stop()
    }

    @Test("Subscriptions reject unary send authorization before starting transport",
          .timeLimit(.minutes(1)), arguments: [false, true])
    func rejectSendAuthorizationForSubscriptions(observed: Bool) async throws {
        let transport = TransportTestActor()
        let client = await SwiftFulcrum.Client(client: FulcrumNetworkClient(
            transport: transport, protocolNegotiation: .init()))
        let options = SwiftFulcrum.Client.Call.Options(sendAuthorization: .init { true })
        do {
            if observed {
                _ = try await client.subscribeObserved(SwiftFulcrum.API.blockchain.headers.subscribe,
                    options: options)
            } else {
                _ = try await client.subscribe(SwiftFulcrum.API.blockchain.headers.subscribe,
                    options: options)
            }
            Issue.record("A subscription must reject unary-only send authorization.")
        } catch let error as SwiftFulcrum.Client.Error {
            #expect(error == .client(.invalidConfiguration("sendAuthorization is supported only for unary requests.")))
        }
        #expect(await transport.sentMessages.isEmpty)
        #expect(await client.isRunning == false)
        #expect(await client.makeActiveSubscriptionCount() == 0)
        await client.stop()
    }

    private func broadcasts(on transport: TransportTestActor) async -> [[String: Any]] {
        await transport.sentMessages.compactMap {
            guard let object = try? TransportTestActor.decodeJSONObject(from: $0),
                  object["method"] as? String == "blockchain.transaction.broadcast" else { return nil }
            return object
        }
    }

    private final class AuthorizationClock: Sendable {
        private let state = Mutex((now: 100.0, checkCount: 0))

        func set(_ now: Double) { state.withLock { $0.now = now } }
        var checkCount: Int { state.withLock { $0.checkCount } }

        func isAuthorized(before expiry: Double) -> Bool {
            state.withLock {
                $0.checkCount += 1
                return $0.now.isFinite && $0.now > 0 && $0.now < expiry
            }
        }
    }

    private actor BroadcastCompletion {
        private(set) var result: Result<Data, SwiftFulcrum.Client.Error>?
        func finish(_ result: Result<Data, SwiftFulcrum.Client.Error>) { self.result = result }
    }
}
