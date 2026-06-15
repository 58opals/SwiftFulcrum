// ClientCancellationValidator~RequestTask.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test("request(task cancellation) does not emit a late request", .timeLimit(.minutes(1)))
    func requestTaskCancellationDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendPaused(true)

        let baselineOutgoingCount = await transport.sentMessages.count
        let completion = CancellationCompletionState()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("request() should throw cancelled when the calling task is cancelled.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseRequestSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseRequestSend)

        requestTask.cancel()
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
        #expect(await fulcrum.makeInflightUnaryCallCount() == 0)

        await fulcrum.stop()
    }

    @Test("request cancellation while negotiating does not hang", .timeLimit(.minutes(1)))
    func requestCancellationWhileNegotiatingDoesNotHang() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        await transport.configureOutgoingSendPaused(true)
        let completion = CancellationCompletionState()

        let requestTask = Task {
            do {
                let _: (UUID, SwiftFulcrum.Response.Server.Ping) = try await networkClient.call(
                    method: .server(.ping),
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("call() should throw cancelled when the calling task is cancelled during negotiation.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseNegotiationSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseNegotiationSend)

        requestTask.cancel()
        await transport.configureOutgoingSendPaused(false)

        let didComplete = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        #expect(didComplete)

        if didComplete {
            #expect(isCancelledError(await completion.recordedError ?? .client(.unknown(nil))))
        }

        try? await Task.sleep(for: .milliseconds(150))
        #expect(await transport.sentMessages.isEmpty)
    }
}
