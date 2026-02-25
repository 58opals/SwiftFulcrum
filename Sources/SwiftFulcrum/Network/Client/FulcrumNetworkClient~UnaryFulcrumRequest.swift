// FulcrumNetworkClient~UnaryFulcrumRequest.swift

import Foundation

extension FulcrumNetworkClient {
    func executeUnaryRequest(id: UUID, request: FulcrumRequest) async throws -> Data {
        try await withTaskCancellationHandler {
            let responseStream = try await registerUnaryResponse(for: id)

            do {
                try Task.checkCancellation()
                try await send(request: request)
                return try await awaitUnaryResponse(from: responseStream)
            } catch {
                if error is CancellationError {
                    await cancelUnary(id, error: FulcrumClient.Error.client(.cancelled))
                    throw FulcrumClient.Error.client(.cancelled)
                }
                await cancelUnary(id, error: error)
                throw error
            }
        } onCancel: {
            Task {
                await self.cancelUnary(id, error: FulcrumClient.Error.client(.cancelled))
            }
        }
    }

    func registerUnaryResponse(for id: UUID) async throws -> AsyncThrowingStream<Data, Swift.Error> {
        let (responseStream, responseContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        let inflightCount = try await router.addUnary(id: id, continuation: responseContinuation)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
        return responseStream
    }

    func awaitUnaryResponse(
        from responseStream: AsyncThrowingStream<Data, Swift.Error>
    ) async throws -> Data {
        var iterator = responseStream.makeAsyncIterator()

        guard let payload = try await iterator.next() else {
            throw FulcrumClient.Error.client(.cancelled)
        }

        return payload
    }
}
