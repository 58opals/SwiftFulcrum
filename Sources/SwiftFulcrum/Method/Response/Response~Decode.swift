// Response~Decode.swift

import Foundation

extension Data {
    func decode<Result: Decodable>(_ type: Result.Type) throws -> Result {
        let rpcResult = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.Generic<Result>.self, from: self)
        let resultType = try rpcResult.getResponseType()
        
        switch resultType {
        case .regular(let regular):
            return regular.result
        case .error(let error):
            throw Fulcrum.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
        case .empty(let uuid):
            throw Fulcrum.Error.client(.emptyResponse(uuid))
        case .subscription(let subscriptionResponse):
            throw Fulcrum.Error.client(.protocolMismatch("Method Path: \(subscriptionResponse.methodPath)"))
        }
    }
}

extension AsyncThrowingStream where Element == Data {
    func decode<Result: Decodable>(_ type: Result.Type) -> AsyncThrowingStream<Result, Swift.Error> {
        AsyncThrowingStream<Result, Swift.Error> { continuation in
            Task {
                do {
                    for try await chunk in self {
                        continuation.yield(try chunk.decode(Result.self))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
