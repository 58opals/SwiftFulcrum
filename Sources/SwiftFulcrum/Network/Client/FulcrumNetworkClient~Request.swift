// FulcrumNetworkClient~Request.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func call<ResponsePayload: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, ResponsePayload) {
        if method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("call() cannot be used with subscription methods. Use subscribe(...) instead.")
            )
        }

        let id = UUID()
        let request = method.createRequest(with: id)
        let timeoutState = RequestTimeoutState()
        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientCallBegin,
            level: .debug,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
            fields: makeRequestDiagnosticFields(methodPath: method.path)
        )

        let callTask = Task<Data, Swift.Error> {
            try await executeUnaryRequest(id: id, request: request, timeoutState: timeoutState)
        }
        let token = options.token
        let cancellationRegistrationID: FulcrumNetworkClient.Call.Token.RegistrationID?
        if let token {
            cancellationRegistrationID = await token.register { [weak self] in
                callTask.cancel()
                guard let self else { return }
                let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                await self.cancelUnary(id, error: cancellationError)
            }
        } else {
            cancellationRegistrationID = nil
        }

        let raw: Data
        do {
            raw = try await withTaskCancellationHandler {
                if let token, await token.isCancelled {
                    let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                    callTask.cancel()
                    await self.cancelUnary(id, error: cancellationError)
                    throw cancellationError
                }

                if let limit = options.timeout {
                    let timeoutError = SwiftFulcrum.Client.Error.client(.timeout(limit))
                    return try await withThrowingTaskGroup(of: Data.self) { group in
                        group.addTask { try await callTask.value }
                        group.addTask {
                            try await Task.sleep(for: limit)
                            await timeoutState.mark(timeoutError)
                            callTask.cancel()
                            await self.cancelUnary(id, error: timeoutError)
                            throw timeoutError
                        }

                        let value = try await group.next()!
                        group.cancelAll()
                        return value
                    }
                }

                return try await callTask.value
            } onCancel: {
                callTask.cancel()
                Task {
                    let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                    await self.cancelUnary(id, error: cancellationError)
                }
            }
        } catch {
            if let token, let cancellationRegistrationID {
                await token.unregister(cancellationRegistrationID)
            }
            if error is CancellationError {
                let cancellationError = await makeRequestCancellationError(using: timeoutState)
                OpalDiagnostics.logger(category: .fulcrum).record(
                    event: await callFailureEvent(for: cancellationError, timeoutState: timeoutState),
                    level: .info,
                    traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                    fields: makeRequestFailureDiagnosticFields(methodPath: method.path, error: cancellationError)
                )
                throw cancellationError
            }
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: await callFailureEvent(for: error, timeoutState: timeoutState),
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                fields: makeRequestFailureDiagnosticFields(methodPath: method.path, error: error)
            )
            throw error
        }

        if let token, let cancellationRegistrationID {
            await token.unregister(cancellationRegistrationID)
        }

        do {
            let response = try raw.decode(ResponsePayload.self, context: .init(methodPath: method.path))
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientCallResponseDecoded,
                level: .debug,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                fields: makeRequestDiagnosticFields(methodPath: method.path, [
                    .swiftFulcrumField("byte_count", raw.count)
                ])
            )
            return (id, response)
        } catch {
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientCallFailed,
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                fields: makeRequestFailureDiagnosticFields(methodPath: method.path, error: error)
            )
            throw error
        }
    }
}
