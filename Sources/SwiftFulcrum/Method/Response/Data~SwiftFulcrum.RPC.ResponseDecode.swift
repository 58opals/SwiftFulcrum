// Data~FulcrumResponseDecode.swift

import Foundation

extension Data {
    func decode<ResultModel: Decodable>(_ type: ResultModel.Type) throws -> ResultModel {
        let rpcResult = try JSONRPCModel.Coder.decoder.decode(SwiftFulcrum.RPC.Response.JSONRPCModel.Generic<ResultModel>.self, from: self)
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
    
    func decode<ResultModel: SwiftFulcrum.RPC.ResponseProtocol>(_ type: ResultModel.Type, context: JSONRPCModel.DecodeContext? = nil) throws -> ResultModel {
        let rpcContainer = try JSONRPCModel.Coder.decoder.decode(
            SwiftFulcrum.RPC.Response.JSONRPCModel.Generic<ResultModel.JSONRPCModel>.self,
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
                throw SwiftFulcrum.Client.Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message))
            case .empty(let uuid):
                throw SwiftFulcrum.Client.Error.client(.emptyResponse(uuid))
            }
        } catch let formatError as SwiftFulcrum.RPC.Response.ResultModel.Error {
            if case .unexpectedFormat(let message) = formatError {
                let methodHint: String? = {
                    if let methodPath = context?.methodPath { return methodPath }
                    return rpcContainer.method
                }()
                let prefix = [
                    methodHint.map { "[method: \($0)]" },
                    "[payload: \(self.count) B]"
                ].compactMap { $0 }.joined(separator: " ")
                throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("\(prefix) \(message)")
            }
            throw formatError
        }
    }
}
