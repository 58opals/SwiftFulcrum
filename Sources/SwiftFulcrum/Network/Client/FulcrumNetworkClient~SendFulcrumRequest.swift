// FulcrumNetworkClient~SendFulcrumRequest.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func send(request: FulcrumRequest) async throws {
        try Task.checkCancellation()

        if case .server(.version) = request.requestedMethod {
            guard let data = request.data else { throw SwiftFulcrum.Client.Error.coding(.encode(nil)) }
            try Task.checkCancellation()
            try await self.send(data: data)
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: request.requestedMethod.isSubscription
                    ? .swiftFulcrumClientSubscribeSent
                    : .swiftFulcrumClientCallSent,
                level: .debug,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: request.id),
                fields: makeRequestDiagnosticFields(methodPath: request.method, [
                    .swiftFulcrumField("byte_count", data.count)
                ])
            )
            return
        }

        _ = try await ensureNegotiatedProtocol()

        guard let data = request.data else { throw SwiftFulcrum.Client.Error.coding(.encode(nil)) }
        try Task.checkCancellation()
        try await self.send(data: data)
        OpalDiagnostics.logger(category: .fulcrum).record(
            event: request.requestedMethod.isSubscription
                ? .swiftFulcrumClientSubscribeSent
                : .swiftFulcrumClientCallSent,
            level: .debug,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: request.id),
            fields: makeRequestDiagnosticFields(methodPath: request.method, [
                .swiftFulcrumField("byte_count", data.count)
            ])
        )
    }

    func cancelUnary(_ id: UUID, error: Swift.Error? = nil) async {
        let inflight = await router.cancel(identifier: .uuid(id), error: error)
        await recordClientState(inflightUnaryCallCount: inflight)
    }
}
