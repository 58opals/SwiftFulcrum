// FulcrumClientLifecycleValidator~RequestStopOrdering.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("stop supersedes request preparation already in flight", .timeLimit(.minutes(1)))
    func preventInflightRequestPreparationFromRestartingAfterStop() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.pauseNextConnectionStateRead()

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("request() should not continue after stop() supersedes preparation.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        let didPauseConnectionStateRead = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingConnectionStateReadCount() == 1
        }
        #expect(didPauseConnectionStateRead)

        await fulcrum.stop()
        await transport.resumePendingConnectionStateReads()

        let error = await requestTask.value
        #expect(error == .client(.cancelled))
        #expect(await transport.makeReconnectAttempts() == 0)
        #expect(await transport.connectionState == .disconnected)
        #expect(await fulcrum.isRunning == false)
    }
}
