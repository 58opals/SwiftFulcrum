import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Router semantics

@Suite("Client.Router semantics")
struct ClientRouterSemanticsTests {
    
    @Test
    func duplicateHandler_thrown_on_double_add() async {
        let router = Client.Router()
        let id = UUID()
        let streamKey = "blockchain.headers.subscribe"

        let (addedSignal, addedContinuation) = AsyncStream<Void>.makeStream()

        let pendingUnary = Task {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Swift.Error>) in
                Task {
                    do {
                        try await router.addUnary(id: id, continuation: continuation)
                        _ = addedContinuation.yield(())
                        addedContinuation.finish()
                    } catch {
                        addedContinuation.finish()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        var iterator = addedSignal.makeAsyncIterator()
        _ = await iterator.next()

        var unaryError: Fulcrum.Error?
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Swift.Error>) in
                Task {
                    do {
                        try await router.addUnary(id: id, continuation: continuation)
                        Issue.record("expected duplicateHandler for unary")
                        await router.cancel(identifier: .uuid(id))
                        continuation.resume(throwing: Fulcrum.Error.client(.duplicateHandler))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            unaryError = error as? Fulcrum.Error
        }
        #expect({ if case .client(.duplicateHandler)? = unaryError { return true }; return false }())

        let (_, streamContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try? await router.addStream(key: streamKey, continuation: streamContinuation)

        var streamError: Fulcrum.Error?
        do {
            let (_, dupContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
            try await router.addStream(key: streamKey, continuation: dupContinuation)
            Issue.record("expected duplicateHandler for stream")
            dupContinuation.finish()
        } catch {
            streamError = error as? Fulcrum.Error
        }
        #expect({ if case .client(.duplicateHandler)? = streamError { return true }; return false }())

        await router.cancel(identifier: .uuid(id))
        _ = await pendingUnary.result
    }
    
    @Test
    func failUnaries_cancels_only_unaries_streams_stay_open() async throws {
        let router = Client.Router()
        let id = UUID()
        let streamKey = "blockchain.headers.subscribe"
        
        let unaryResult = Task<Bool, Never> {
            do {
                _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Swift.Error>) in
                    Task { try await router.addUnary(id: id, continuation: continuation) }
                }
                return false
            } catch let error as Fulcrum.Error {
                if case .transport(.connectionClosed(_, _)) = error { return true }
                return false
            } catch { return false }
        }
        
        let (stream, streamContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try await router.addStream(key: streamKey, continuation: streamContinuation)
        var iterator = stream.makeAsyncIterator()
        
        let closed = Fulcrum.Error.transport(.connectionClosed(.goingAway, "test"))
        await router.failUnaries(with: closed)
        
        #expect(await unaryResult.value)
        
        let notification: [String: Any] = [
            "jsonrpc": "2.0",
            "method": streamKey,
            "params": [[
                "height": 1,
                "hex": "00"
            ]]
        ]
        let raw = try JSONSerialization.data(withJSONObject: notification, options: [])
        await router.handle(raw: raw)
        
        let yielded = try await iterator.next()
        #expect(yielded != nil)
    }
}
