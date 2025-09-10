import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Cancellation and timeout

@Suite("Cancellation and timeout")
struct CancellationAndTimeoutTests {
    
    @Test
    func token_cancels_in_flight_unary_and_stream() async {
        let router = Client.Router()
        let id = UUID()
        let streamKey = "blockchain.headers.subscribe"
        let token = Client.Call.Token()
        
        let unaryCancelled = Task<Bool, Never> {
            do {
                _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Swift.Error>) in
                    Task { try await router.addUnary(id: id, continuation: continuation) }
                }
                return false
            } catch let error as Fulcrum.Error {
                if case .client(.cancelled) = error { return true }
                return false
            } catch { return false }
        }
        
        let (stream, streamContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try? await router.addStream(key: streamKey, continuation: streamContinuation)
        let streamFinished = Task<Bool, Never> {
            var iterator = stream.makeAsyncIterator()
            let next = try? await iterator.next()
            return next == nil
        }
        
        await token.register { @Sendable in
            Task {
                await router.cancel(identifier: .uuid(id))
                await router.cancel(identifier: .string(streamKey))
            }
        }
        await token.cancel()
        
        #expect(await unaryCancelled.value)
        #expect(await streamFinished.value)
    }
    
    @Test
    func options_timeout_yields_client_timeout() async {
        actor TimeoutHarness {
            let router = Client.Router()
            
            func callWithTimeout(_ limit: Duration) async throws -> Data {
                let id = UUID()
                let callTask = Task<Data, Swift.Error> {
                    try await withTaskCancellationHandler {
                        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Data, Swift.Error>) in
                            Task { try await router.addUnary(id: id, continuation: c) }
                        }
                    } onCancel: {
                        Task { await self.router.cancel(identifier: .uuid(id)) }
                    }
                }
                return try await withThrowingTaskGroup(of: Data.self) { group in
                    group.addTask { try await callTask.value }
                    group.addTask {
                        try await Task.sleep(for: limit)
                        callTask.cancel()
                        throw Fulcrum.Error.client(.timeout(limit))
                    }
                    let value = try await group.next()!
                    group.cancelAll()
                    return value
                }
            }
        }
        
        let harness = TimeoutHarness()
        do {
            _ = try await harness.callWithTimeout(.milliseconds(25))
            Issue.record("expected timeout")
        } catch let error as Fulcrum.Error {
            #expect({
                if case .client(.timeout(let duration)) = error { return duration == .milliseconds(25) }
                return false
            }())
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
