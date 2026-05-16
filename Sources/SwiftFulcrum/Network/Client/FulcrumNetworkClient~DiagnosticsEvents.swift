// FulcrumNetworkClient~DiagnosticsEvents.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func recordClientEvent(
        _ event: OpalDiagnostics.Event,
        category: OpalDiagnostics.Category = SwiftFulcrumDiagnostics.Category.fulcrum,
        level: OpalDiagnostics.Level = .debug,
        traceID: OpalDiagnostics.TraceID? = nil,
        fields: [OpalDiagnostics.Field] = []
    ) {
        SwiftFulcrumDiagnostics.record(
            event,
            category: category,
            level: level,
            traceID: traceID,
            fields: [SwiftFulcrumDiagnostics.publicField("client_id", id)] + fields
        )
    }

    func recordRequestSent(_ request: FulcrumRequest, byteCount: Int) {
        recordClientEvent(
            request.requestedMethod.isSubscription
                ? SwiftFulcrumDiagnostics.Event.clientSubscribeSent
                : SwiftFulcrumDiagnostics.Event.clientCallSent,
            traceID: SwiftFulcrumDiagnostics.traceID(for: request.id),
            fields: [
                SwiftFulcrumDiagnostics.methodField(request.method),
                SwiftFulcrumDiagnostics.publicField("byte_count", byteCount)
            ]
        )
    }

    func recordRequestFailure(
        _ event: OpalDiagnostics.Event,
        requestID: UUID,
        methodPath: String,
        error: Swift.Error
    ) {
        recordClientEvent(
            event,
            level: .error,
            traceID: SwiftFulcrumDiagnostics.traceID(for: requestID),
            fields: [
                SwiftFulcrumDiagnostics.methodField(methodPath)
            ] + SwiftFulcrumDiagnostics.errorFields(error)
        )
    }
}
