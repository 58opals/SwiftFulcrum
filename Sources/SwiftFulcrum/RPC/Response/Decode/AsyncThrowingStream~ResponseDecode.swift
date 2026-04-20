// AsyncThrowingStream~ResponseDecode.swift

import Foundation

extension AsyncThrowingStream where Element == Data, Failure == Swift.Error {
    func decode<Payload: Decodable & Sendable>(
        _ type: Payload.Type,
        context: JSONRPCCodec.DecodeContext? = nil,
        onTermination: (@Sendable () -> Void)? = nil
    ) -> AsyncThrowingStream<Payload, Swift.Error> {
        let iterator = DataStreamIterator(stream: self, onTermination: onTermination)
        return AsyncThrowingStream<Payload, Swift.Error> {
            guard let chunk = try await iterator.next() else {
                return nil
            }
            return try chunk.decode(Payload.self, context: context)
        }
    }
}
