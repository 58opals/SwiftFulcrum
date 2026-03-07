// Data~ResponseDecode.swift

import Foundation

extension Data {
    func decode<Payload: Decodable>(_ type: Payload.Type) throws -> Payload {
        let rpcResult = try JSONRPCCodec.Coder.decoder.decode(SwiftFulcrum.RPC.Response.JSONRPC.Generic<Payload>.self, from: self)
        let resultType = try rpcResult.determineResponseType()
        
        switch resultType {
        case .regular(let regular):
            return regular.result
        case .subscription(let subscriptionResponse):
            return subscriptionResponse.result
        case .error(let error):
            throw SwiftFulcrum.Client.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
        case .empty(let uuid):
            throw SwiftFulcrum.Client.Error.client(.emptyResponse(uuid))
        }
    }
    
    func decode<ResponsePayload: SwiftFulcrum.RPC.JSONRPCResponseAdapter>(_ type: ResponsePayload.Type, context: JSONRPCCodec.DecodeContext? = nil) throws -> ResponsePayload {
        let rpcContainer = try JSONRPCCodec.Coder.decoder.decode(
            SwiftFulcrum.RPC.Response.JSONRPC.Generic<ResponsePayload.JSONRPC>.self,
            from: self
        )
        let responseKind = try rpcContainer.determineResponseType()
        do {
            switch responseKind {
            case .regular(let regular):
                return try ResponsePayload(fromRPC: regular.result)
            case .subscription(let subscriptionResponse):
                return try ResponsePayload(fromRPC: subscriptionResponse.result)
            case .error(let error):
                throw SwiftFulcrum.Client.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
            case .empty(let uuid):
                throw SwiftFulcrum.Client.Error.client(.emptyResponse(uuid))
            }
        } catch let formatError as ResponseResultDecodeError {
            if case .unexpectedFormat(let message) = formatError {
                let methodHint: String? = {
                    if let methodPath = context?.methodPath { return methodPath }
                    return rpcContainer.method
                }()
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
