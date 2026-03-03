import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientCancellationValidator {
    @Test("Shared cancellation cancels every in-flight unary call", .timeLimit(.minutes(1)))
    func sharedCancellationCancelsAllInflightUnaryCalls() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = FulcrumClient.CallModel.Cancellation()
        let options = FulcrumClient.CallModel.Options(
            timeout: .milliseconds(250),
            cancellation: cancellation
        )
        
        let firstTask = Task<FulcrumClient.Error, Never> {
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    responseType: FulcrumResponse.ResultModel.Blockchain.Headers.GetTip.self,
                    options: options
                )
                Issue.record("First submit should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as FulcrumClient.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let secondTask = Task<FulcrumClient.Error, Never> {
            do {
                _ = try await fulcrum.submit(
                    method: .mempool(.getInfo),
                    responseType: FulcrumResponse.ResultModel.Mempool.GetInfo.self,
                    options: options
                )
                Issue.record("Second submit should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as FulcrumClient.Error {
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
    
    @Test("submit(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func submitTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let submitTask = Task<FulcrumClient.Error, Never> {
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    responseType: FulcrumResponse.ResultModel.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("submit() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as FulcrumClient.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let error = await submitTask.value
        #expect(isTimeoutError(error))
        
        try? await Task.sleep(for: .milliseconds(1_200))
        let finalOutgoingCount = await transport.sentMessages.count
        #expect(finalOutgoingCount == baselineOutgoingCount)
        
        await fulcrum.stop()
    }
    
    @Test("subscribe(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func subscribeTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let subscribeTask = Task<FulcrumClient.Error, Never> {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initialType: FulcrumResponse.ResultModel.Blockchain.Headers.Subscribe.self,
                    notificationType: FulcrumResponse.ResultModel.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as FulcrumClient.Error {
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
}

extension ClientCancellationValidator {
    private func isCancelledError(_ error: FulcrumClient.Error) -> Bool {
        if case .client(.cancelled) = error {
            return true
        }
        
        return false
    }
    
    private func isTimeoutError(_ error: FulcrumClient.Error) -> Bool {
        if case .client(.timeout) = error {
            return true
        }
        
        return false
    }
    
    func makeStartedFulcrum() async throws -> (FulcrumClient, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await FulcrumClient(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }
    
    private func startAndNegotiate(_ fulcrum: FulcrumClient, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }
        
        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["FulcrumClient 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))
        
        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "FulcrumClient 2.0",
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
