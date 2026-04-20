// Response+JSONRPC.swift

import Foundation

extension SwiftFulcrum.RPC.Response {
    struct JSONRPC {}
}

extension SwiftFulcrum.RPC.Response.JSONRPC: Sendable {}

extension SwiftFulcrum.RPC.Response.JSONRPC {
    static func extractIdentifier(from data: Data) throws -> SwiftFulcrum.RPC.Response.Identifier {
        let response = try JSONRPCCodec.Coder.decoder.decode(JSONRPCResponseDecodeModel.IdentifierEnvelopeModel.self, from: data)
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
            JSONRPCResponseDecodeModel.ErasedResponseEnvelopeModel.self,
            from: data
        )

        if let id = response.id, response.error == nil, response.hasResult {
            return .regular(id)
        }

        if let id = response.id, let error = response.error {
            return .error(.rpc(.init(id: id, code: error.code, message: error.message)))
        }

        if let id = response.id {
            return .empty(id)
        }

        throw JSONRPCResponseDecodeError.cannotIdentifyResponseType(response.id)
    }
}
