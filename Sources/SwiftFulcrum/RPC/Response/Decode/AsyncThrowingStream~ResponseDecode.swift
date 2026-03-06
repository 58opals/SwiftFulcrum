// AsyncThrowingStream~ResponseDecode.swift

import Foundation

extension AsyncThrowingStream where Element == Data, Failure == Swift.Error {
    func decode<Payload: Decodable & Sendable>(_ type: Payload.Type) -> AsyncThrowingStream<Payload, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<Payload, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(Payload.self)
        }
    }

    func decode<ResponsePayload: SwiftFulcrum.RPC.JSONRPCResponseAdapter>(_ type: ResponsePayload.Type) -> AsyncThrowingStream<ResponsePayload, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<ResponsePayload, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(ResponsePayload.self)
        }
    }

    func decode<ResponsePayload: SwiftFulcrum.RPC.JSONRPCResponseAdapter>(_ type: ResponsePayload.Type, context: JSONRPCCodec.DecodeContext?) -> AsyncThrowingStream<ResponsePayload, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<ResponsePayload, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(ResponsePayload.self, context: context)
        }
    }
}
