// AsyncThrowingStream~ResponseDecode.swift

import Foundation

extension AsyncThrowingStream where Element == Data, Failure == Swift.Error {
    func decode<Payload: Decodable & Sendable>(
        _ type: Payload.Type,
        context: JSONRPCCodec.DecodeContext? = nil
    ) -> AsyncThrowingStream<Payload, Swift.Error> {
        let iteratorModel = DataStreamIteratorModel(stream: self)
        return AsyncThrowingStream<Payload, Swift.Error> {
            guard let chunk = try await iteratorModel.next() else {
                return nil
            }
            return try chunk.decode(Payload.self, context: context)
        }
    }
}
