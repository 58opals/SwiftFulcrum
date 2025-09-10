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

        let (addedSignal, addedCont) = AsyncStream<Void>.makeStream()

        let pendingUnary = Task {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Data, Swift.Error>) in
                Task {
                    do {
                        try await router.addUnary(id: id, continuation: c)
                        _ = addedCont.yield(())
                        addedCont.finish()
                    } catch {
                        addedCont.finish()
                        c.resume(throwing: error)       // <- ensure no leak on failure
                    }
                }
            }
        }

        var it = addedSignal.makeAsyncIterator()
        _ = await it.next()

        var unaryErr: Fulcrum.Error?
        do {
            _ = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Data, Swift.Error>) in
                Task {
                    do {
                        try await router.addUnary(id: id, continuation: c)
                        // Should not happen; avoid leaking the continuation.
                        Issue.record("expected duplicateHandler for unary")
                        await router.cancel(identifier: .uuid(id))
                        c.resume(throwing: Fulcrum.Error.client(.duplicateHandler))
                    } catch {
                        c.resume(throwing: error)       // <- ensure resume on error
                    }
                }
            }
        } catch {
            unaryErr = error as? Fulcrum.Error
        }
        #expect({ if case .client(.duplicateHandler)? = unaryErr { return true }; return false }())

        // Seed a stream
        let (_, streamCont) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try? await router.addStream(key: streamKey, continuation: streamCont)

        // Second stream with the same key must throw duplicateHandler
        var streamErr: Fulcrum.Error?
        do {
            let (_, dupCont) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
            try await router.addStream(key: streamKey, continuation: dupCont)
            Issue.record("expected duplicateHandler for stream")
            dupCont.finish() // tidy up if unexpectedly added
        } catch {
            streamErr = error as? Fulcrum.Error
        }
        #expect({ if case .client(.duplicateHandler)? = streamErr { return true }; return false }())

        // Cleanup the seeded unary
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
                _ = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Data, Swift.Error>) in
                    Task { try await router.addUnary(id: id, continuation: c) }
                }
                return false
            } catch let e as Fulcrum.Error {
                if case .transport(.connectionClosed(_, _)) = e { return true }
                return false
            } catch { return false }
        }
        
        let (stream, streamCont) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        try await router.addStream(key: streamKey, continuation: streamCont)
        var it = stream.makeAsyncIterator()
        
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
        
        let yielded = try await it.next()
        #expect(yielded != nil)
    }
}
