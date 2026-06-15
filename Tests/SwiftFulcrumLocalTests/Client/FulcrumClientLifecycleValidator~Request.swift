// FulcrumClientLifecycleValidator~Request.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("request(timeout:) throws timeout when unary response is missing", .timeLimit(.minutes(1)))
    func requestTimeoutWhenUnaryResponseMissing() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("request() should time out when response is missing")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)

        await requestTask.value
        await fulcrum.stop()
    }

    @Test("request(cancellation:) throws cancelled", .timeLimit(.minutes(1)))
    func requestCancellationPropagatesCancelledError() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
                    options: .init(timeout: .seconds(30), cancellation: cancellation)
                )
                Issue.record("request() should throw cancelled")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.cancelled) = error else {
                    Issue.record("Expected cancelled, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        _ = try await decodeRequestObject(await transport.dequeueOutgoing())
        await cancellation.cancel()

        await requestTask.value
        await fulcrum.stop()
    }
}
