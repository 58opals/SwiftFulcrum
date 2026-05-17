// Response+JSONRPC.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    struct JSONRPC {}
}

extension SwiftFulcrum.RPC.Response.JSONRPC: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPC {
    static func extractIdentifier(from data: Data) throws -> SwiftFulcrum.RPC.Response.Identifier {
        let response = try JSONRPCCodec.Coder.decoder.decode(JSONRPCResponseDecodeModel.IdentifierEnvelope.self, from: data)
        switch (response.id, response.method) {
        case let (id?, nil):
            return .uuid(id)
        case let (nil, string?):
            return .string(string)
        default:
            throw JSONRPCResponseDecodeError.wrongResponseType
        }
    }

    static func classifyErasedResponse(from data: Data) throws -> ErasedResponseKind {
        let response = try JSONRPCCodec.Coder.decoder.decode(
            JSONRPCResponseDecodeModel.ErasedResponseEnvelope.self,
            from: data
        )

        if response.hasMethod || response.hasParams {
            throw JSONRPCResponseDecodeError.wrongResponseType
        }

        if response.hasError && response.hasResult {
            throw JSONRPCResponseDecodeError.wrongResponseType
        }

        if response.hasError {
            guard let error = response.error else {
                throw JSONRPCResponseDecodeError.wrongResponseType
            }
            return .error(.rpc(.init(id: response.id, code: error.code, message: error.message)))
        }

        if let id = response.id, response.hasResult {
            return .regular(id)
        }

        if let id = response.id {
            return .empty(id)
        }

        throw JSONRPCResponseDecodeError.cannotIdentifyResponseType(response.id)
    }
}
