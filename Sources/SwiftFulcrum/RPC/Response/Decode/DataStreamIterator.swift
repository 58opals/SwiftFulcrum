// DataStreamIterator.swift

import Foundation

actor DataStreamIterator<Failure: Swift.Error> {
    private let nextChunk: () async throws -> Data?
    private let onTermination: (@Sendable () -> Void)?

    init(
        stream: AsyncThrowingStream<Data, Failure>,
        onTermination: (@Sendable () -> Void)? = nil
    ) {
        var iterator = stream.makeAsyncIterator()
        self.nextChunk = {
            try await iterator.next()
        }
        self.onTermination = onTermination
    }

    func next() async throws -> Data? {
        try await nextChunk()
    }

    deinit {
        onTermination?()
    }
}
