// AsyncThrowingStream~FulcrumResponseDecode.swift

import Foundation

extension AsyncThrowingStream where Element == Data, Failure == Swift.Error {
    func decode<ResultModel: Decodable & Sendable>(_ type: ResultModel.Type) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<ResultModel, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(ResultModel.self)
        }
    }

    func decode<ResultModel: SwiftFulcrum.RPC.ResponseProtocol>(_ type: ResultModel.Type) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<ResultModel, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(ResultModel.self)
        }
    }

    func decode<ResultModel: SwiftFulcrum.RPC.ResponseProtocol>(_ type: ResultModel.Type, context: JSONRPCModel.DecodeContext?) -> AsyncThrowingStream<ResultModel, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<ResultModel, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(ResultModel.self, context: context)
        }
    }
}
