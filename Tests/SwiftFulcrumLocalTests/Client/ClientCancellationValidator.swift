// ClientCancellationValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientCancellationValidator {
    @Test("Shared cancellation cancels every in-flight unary call", .timeLimit(.minutes(1)))
    func sharedCancellationCancelsAllInflightUnaryCalls() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()
        let options = SwiftFulcrum.Client.Call.Options(
            timeout: .milliseconds(250),
            cancellation: cancellation
        )
        
        let firstTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: options
                )
                Issue.record("First request should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let secondTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .mempool(.getInfo),
                    responseType: SwiftFulcrum.RPC.Response.Result.Mempool.GetInfo.self,
                    options: options
                )
                Issue.record("Second request should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        _ = await transport.dequeueOutgoing()
        _ = await transport.dequeueOutgoing()
        await cancellation.cancel()
        
        let firstError = await firstTask.value
        let secondError = await secondTask.value
        
        #expect(isCancelledError(firstError))
        #expect(isCancelledError(secondError))
        
        await fulcrum.stop()
    }
    
    @Test("request(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func requestTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("request() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let error = await requestTask.value
        #expect(isTimeoutError(error))
        
        try? await Task.sleep(for: .milliseconds(1_200))
        let finalOutgoingCount = await transport.sentMessages.count
        #expect(finalOutgoingCount == baselineOutgoingCount)
        
        await fulcrum.stop()
    }

    @Test("request(timeout:) uses one end-to-end budget when starting from idle", .timeLimit(.minutes(1)))
    func requestTimeoutUsesSingleBudgetWhenStartingFromIdle() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(120))

        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let timeout: Duration = .milliseconds(200)

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("request() should time out after spending the single end-to-end budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
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

        let error = await requestTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == 2)

        await client.stop()
    }
    
    @Test("subscribe(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func subscribeTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let subscribeTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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
        
        let snapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(snapshot.activeSubscriptionCount == 0)
        
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
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
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
        #expect((await client.listSubscriptions()).isEmpty)
        #expect((await client.makeDiagnosticsSnapshot()).activeSubscriptionCount == 0)

        await client.stop()
    }
}

extension ClientCancellationValidator {
    private func isCancelledError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.cancelled) = error {
            return true
        }
        
        return false
    }
    
    private func isTimeoutError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.timeout) = error {
            return true
        }
        
        return false
    }
    
    func makeStartedFulcrum() async throws -> (SwiftFulcrum.Client, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }
    
    private func startAndNegotiate(_ fulcrum: SwiftFulcrum.Client, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }
        
        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))
        
        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
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
        
        _ = try await startTask.value
    }
    
    private func requestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }
        
        return identifier
    }
    
    private enum SupportError: Swift.Error {
        case missingRequestIdentifier
    }
}
