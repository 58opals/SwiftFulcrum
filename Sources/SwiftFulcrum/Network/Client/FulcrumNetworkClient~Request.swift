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
        let timeoutState = FulcrumNetworkClient.Call.TimeoutState()
        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientCallBegin,
            level: .debug,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
            fields: makeRequestDiagnosticFields(methodPath: method.path)
        )

        let callTask = Task<Data, Swift.Error> {
            try await executeUnaryRequest(id: id, request: request, timeoutState: timeoutState)
        }
        let executionContext = FulcrumNetworkClient.Call.ExecutionContext(
            task: callTask,
            token: options.token,
            timeout: options.timeout,
            timeoutState: timeoutState
        ) { [weak self] cancellationError in
            await self?.cancelUnary(id, error: cancellationError)
        }

        let raw: Data
        do {
            raw = try await executionContext.value()
        } catch {
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
