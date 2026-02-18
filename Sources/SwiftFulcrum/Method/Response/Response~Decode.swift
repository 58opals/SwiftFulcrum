// Response~Decode.swift

import Foundation

extension Data {
    func decode<ResultModel: Decodable>(_ type: ResultModel.Type) throws -> ResultModel {
        let rpcResult = try JSONRPCModel.CoderModel.decoder.decode(Response.JSONRPCModel.GenericModel<ResultModel>.self, from: self)
        let resultType = try rpcResult.determineResponseType()
        
        switch resultType {
        case .regular(let regular):
            return regular.result
        case .subscription(let subscriptionResponse):
            return subscriptionResponse.result
        case .error(let error):
            throw FulcrumClient.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
        case .empty(let uuid):
            throw FulcrumClient.Error.client(.emptyResponse(uuid))
        }
    }
    
    func decode<ResultModel: JSONRPCResponse>(_ type: ResultModel.Type, context: JSONRPCModel.DecodeContextModel? = nil) throws -> ResultModel {
        let rpcContainer = try JSONRPCModel.CoderModel.decoder.decode(
            Response.JSONRPCModel.GenericModel<ResultModel.JSONRPCModel>.self,
            from: self
        )
        let responseKind = try rpcContainer.determineResponseType()
        do {
            switch responseKind {
            case .regular(let regular):
                return try ResultModel(fromRPC: regular.result)
            case .subscription(let subscriptionResponse):
                return try ResultModel(fromRPC: subscriptionResponse.result)
            case .error(let error):
                throw FulcrumClient.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
            case .empty(let uuid):
                throw FulcrumClient.Error.client(.emptyResponse(uuid))
            }
        } catch let formatError as Response.ResultModel.Error {
            if case .unexpectedFormat(let message) = formatError {
                let methodHint: String? = {
                    if let methodPath = context?.methodPath { return methodPath }
                    return rpcContainer.method
                }()
                let prefix = [
                    methodHint.map { "[method: \($0)]" },
                    "[payload: \(self.count) B]"
                ].compactMap { $0 }.joined(separator: " ")
                throw Response.ResultModel.Error.unexpectedFormat("\(prefix) \(message)")
            }
            throw formatError
        }
    }
}

extension AsyncThrowingStream where Element == Data {
    func decode<ResultModel: Decodable & Sendable>(_ type: ResultModel.Type) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        AsyncThrowingStream<ResultModel, Swift.Error> { continuation in
            Task {
                do {
                    for try await chunk in self {
                        continuation.yield(try chunk.decode(ResultModel.self))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func decode<ResultModel: JSONRPCResponse>(_ type: ResultModel.Type) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        AsyncThrowingStream<ResultModel, Swift.Error> { continuation in
            Task {
                do {
                    for try await chunk in self {
                        continuation.yield(try chunk.decode(ResultModel.self))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func decode<ResultModel: JSONRPCResponse>(_ type: ResultModel.Type, context: JSONRPCModel.DecodeContextModel?) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        AsyncThrowingStream<ResultModel, Swift.Error> { continuation in
            Task {
                do {
                    for try await chunk in self {
                        continuation.yield(try chunk.decode(ResultModel.self, context: context))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
