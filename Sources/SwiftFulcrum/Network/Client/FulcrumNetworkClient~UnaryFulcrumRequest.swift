// FulcrumNetworkClient~UnaryFulcrumRequest.swift

import Foundation

extension FulcrumNetworkClient {
    func executeUnaryRequest(
        id: UUID,
        request: FulcrumRequest,
        timeoutState: RequestTimeoutState? = nil
    ) async throws -> Data {
        try await withTaskCancellationHandler {
            let responseStream = try await registerUnaryResponse(for: id)

            do {
                try Task.checkCancellation()
                try await send(request: request)
                return try await awaitUnaryResponse(from: responseStream, timeoutState: timeoutState)
            } catch {
                if error is CancellationError {
                    let cancellationError = await makeRequestCancellationError(using: timeoutState)
                    await cancelUnary(id, error: cancellationError)
                    throw cancellationError
                }
                await cancelUnary(id, error: error)
                throw error
            }
        } onCancel: {
            Task {
                let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                await self.cancelUnary(id, error: cancellationError)
            }
        }
    }

    func registerUnaryResponse(for id: UUID) async throws -> AsyncThrowingStream<Data, Swift.Error> {
        let (responseStream, responseContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        let inflightCount = try await router.addUnary(id: id, continuation: responseContinuation)
        await recordClientState(inflightUnaryCallCount: inflightCount)
        return responseStream
    }

    func awaitUnaryResponse(
        from responseStream: AsyncThrowingStream<Data, Swift.Error>,
        timeoutState: RequestTimeoutState? = nil
    ) async throws -> Data {
        var iterator = responseStream.makeAsyncIterator()

        guard let payload = try await iterator.next() else {
            if let timeoutState, let timeoutError = await timeoutState.timeoutError {
                throw timeoutError
            }
            throw SwiftFulcrum.Client.Error.client(.cancelled)
        }

        return payload
    }

    func makeRequestCancellationError(using timeoutState: RequestTimeoutState?) async -> SwiftFulcrum.Client.Error {
        if let timeoutState, let timeoutError = await timeoutState.timeoutError {
            return timeoutError
        }

        return SwiftFulcrum.Client.Error.client(.cancelled)
    }
}
