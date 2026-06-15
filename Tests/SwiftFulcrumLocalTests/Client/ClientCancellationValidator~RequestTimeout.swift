// ClientCancellationValidator~RequestTimeout.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test("request(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func requestTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))

        let baselineOutgoingCount = await transport.sentMessages.count

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
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
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
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

        let error = await requestTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == 2)

        await client.stop()
    }
}
