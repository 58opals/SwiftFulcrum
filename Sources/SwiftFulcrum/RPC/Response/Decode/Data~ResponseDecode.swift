// Data~ResponseDecode.swift

import Foundation
import OpalDiagnostics

extension Data {
    func decode<Payload: Decodable & Sendable>(
        _ type: Payload.Type,
        context: JSONRPCCodec.DecodeContext? = nil
    ) throws -> Payload {
        let identifierEnvelope = try? JSONRPCCodec.Coder.decoder.decode(
            JSONRPCResponseDecodeModel.IdentifierEnvelope.self,
            from: self
        )
        let envelopeMethodPath = identifierEnvelope?.method
        let methodHint = context?.methodPath ?? envelopeMethodPath
        let traceID = identifierEnvelope?.id.map { SwiftFulcrumDiagnostics.traceID(for: $0) }

        let responseKind: SwiftFulcrum.RPC.Response.Kind<Payload>
        do {
            let rpcContainer = try JSONRPCCodec.Coder.decoder.decode(
                SwiftFulcrum.RPC.Response.JSONRPC.Generic<Payload>.self,
                from: self
            )
            responseKind = try rpcContainer.determineResponseType()
        } catch let formatError as ResponseResultDecodeError {
            if case .unexpectedFormat(let message) = formatError {
                let prefix = [
                    methodHint.map { "[method: \($0)]" },
                    "[payload: \(self.count) B]"
                ].compactMap { $0 }.joined(separator: " ")
                let reportedError = ResponseResultDecodeError.unexpectedFormat("\(prefix) \(message)")
                recordResponseDecodeFailed(methodHint: methodHint, traceID: traceID, error: reportedError)
                throw reportedError
            }
            recordResponseDecodeFailed(methodHint: methodHint, traceID: traceID, error: formatError)
            throw formatError
        } catch {
            recordResponseDecodeFailed(methodHint: methodHint, traceID: traceID, error: error)
            throw error
        }

        switch responseKind {
        case .regular(let regular):
            recordResponseDecodeSucceeded(methodHint: methodHint, traceID: traceID)
            return regular.result
        case .subscription(let subscriptionResponse):
            recordResponseDecodeSucceeded(methodHint: methodHint, traceID: traceID)
            return subscriptionResponse.result
        case .error(let error):
            recordResponseDecodeSucceeded(methodHint: methodHint, traceID: traceID)
            throw SwiftFulcrum.Client.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
        case .empty(let uuid):
            let error = SwiftFulcrum.Client.Error.client(.emptyResponse(uuid))
            recordResponseDecodeFailed(methodHint: methodHint, traceID: traceID, error: error)
            throw error
        }
    }

    private func recordResponseDecodeSucceeded(
        methodHint: String?,
        traceID: OpalDiagnostics.TraceID?
    ) {
        SwiftFulcrumDiagnostics.record(
            SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecoded,
            category: SwiftFulcrumDiagnostics.Category.jsonRPC,
            traceID: traceID,
            fields: responseDecodeFields(methodHint: methodHint)
        )
    }

    private func recordResponseDecodeFailed(
        methodHint: String?,
        traceID: OpalDiagnostics.TraceID?,
        error: Swift.Error
    ) {
        SwiftFulcrumDiagnostics.record(
            SwiftFulcrumDiagnostics.Event.jsonRPCResponseDecodeFailed,
            category: SwiftFulcrumDiagnostics.Category.jsonRPC,
            level: .error,
            traceID: traceID,
            fields: responseDecodeFields(methodHint: methodHint) + SwiftFulcrumDiagnostics.errorFields(error)
        )
    }

    private func responseDecodeFields(methodHint: String?) -> [OpalDiagnostics.Field] {
        [
            methodHint.map { SwiftFulcrumDiagnostics.publicField("method_hint", $0) },
            SwiftFulcrumDiagnostics.publicField("byte_count", count)
        ].compactMap { $0 }
    }
}
