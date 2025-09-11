// Response~Decode.swift

import Foundation

extension Data {
    func decode<Result: Decodable>(_ type: Result.Type) throws -> Result {
        let rpcResult = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.Generic<Result>.self, from: self)
        let resultType = try rpcResult.getResponseType()
        
        switch resultType {
        case .regular(let regular):
            return regular.result
        case .subscription(let subscriptionResponse):
            return subscriptionResponse.result
        case .error(let error):
            throw Fulcrum.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
        case .empty(let uuid):
            throw Fulcrum.Error.client(.emptyResponse(uuid))
        }
    }
    
    func decode<Result: JSONRPCConvertible>(_ type: Result.Type, context: JSONRPC.DecodeContext? = nil) throws -> Result {
        let rpcContainer = try JSONRPC.Coder.decoder.decode(
            Response.JSONRPC.Generic<Result.JSONRPC>.self,
            from: self
        )
        let responseKind = try rpcContainer.getResponseType()
        do {
            switch responseKind {
            case .regular(let regular):
                return try Result(fromRPC: regular.result)
            case .subscription(let subscriptionResponse):
                return try Result(fromRPC: subscriptionResponse.result)
            case .error(let error):
                throw Fulcrum.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
            case .empty(let uuid):
                throw Fulcrum.Error.client(.emptyResponse(uuid))
            }
        } catch let formatError as Response.Result.Error {
            if case .unexpectedFormat(let message) = formatError {
                let methodHint: String? = {
                    if let methodPath = context?.methodPath { return methodPath }
                    return rpcContainer.method
                }()
                let prefix = [
                    methodHint.map { "[method: \($0)]" },
                    "[payload: \(self.count) B]"
                ].compactMap { $0 }.joined(separator: " ")
                throw Response.Result.Error.unexpectedFormat("\(prefix) \(message)")
            }
            throw formatError
        }
    }
}

extension AsyncThrowingStream where Element == Data {
    func decode<Result: Decodable & Sendable>(_ type: Result.Type) -> AsyncThrowingStream<Result, Swift.Error> {
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
    
    func decode<Result: JSONRPCConvertible>(_ type: Result.Type) -> AsyncThrowingStream<Result, Swift.Error> {
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
    
    func decode<Result: JSONRPCConvertible>(_ type: Result.Type, context: JSONRPC.DecodeContext?) -> AsyncThrowingStream<Result, Swift.Error> {
        AsyncThrowingStream<Result, Swift.Error> { continuation in
            Task {
                do {
                    for try await chunk in self {
                        continuation.yield(try chunk.decode(Result.self, context: context))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
