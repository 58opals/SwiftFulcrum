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

        switch (response.id, response.error, response.hasError, response.hasResult) {
        case (_, _, true, true):
            throw JSONRPCResponseDecodeError.wrongResponseType
        case (_, nil, true, false):
            throw JSONRPCResponseDecodeError.wrongResponseType
        case let (id?, nil, false, true):
            return .regular(id)
        case let (id?, error?, true, false):
            return .error(.rpc(.init(id: id, code: error.code, message: error.message)))
        case let (id?, nil, false, false):
            return .empty(id)
        default:
            throw JSONRPCResponseDecodeError.cannotIdentifyResponseType(response.id)
        }
    }
}
