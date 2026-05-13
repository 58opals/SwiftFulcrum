// Data~ResponseDecode.swift

import Foundation

extension Data {
    func decode<Payload: Decodable & Sendable>(
        _ type: Payload.Type,
        context: JSONRPCCodec.DecodeContext? = nil
    ) throws -> Payload {
        let envelopeMethodPath = try? JSONRPCCodec.Coder.decoder
            .decode(JSONRPCResponseDecodeModel.IdentifierEnvelope.self, from: self)
            .method

        do {
            let rpcContainer = try JSONRPCCodec.Coder.decoder.decode(
                SwiftFulcrum.RPC.Response.JSONRPC.Generic<Payload>.self,
                from: self
            )
            let responseKind = try rpcContainer.determineResponseType()

            switch responseKind {
            case .regular(let regular):
                return regular.result
            case .subscription(let subscriptionResponse):
                return subscriptionResponse.result
            case .error(let error):
                throw SwiftFulcrum.Client.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
            case .empty(let uuid):
                throw SwiftFulcrum.Client.Error.client(.emptyResponse(uuid))
            }
        } catch let formatError as ResponseResultDecodeError {
            if case .unexpectedFormat(let message) = formatError {
                let methodHint = context?.methodPath ?? envelopeMethodPath
                let prefix = [
                    methodHint.map { "[method: \($0)]" },
                    "[payload: \(self.count) B]"
                ].compactMap { $0 }.joined(separator: " ")
                throw ResponseResultDecodeError.unexpectedFormat("\(prefix) \(message)")
            }
            throw formatError
        }
    }
}
