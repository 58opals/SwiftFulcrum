// DataStreamIterator.swift

import Foundation

final class DataStreamIterator<Failure: Swift.Error>: @unchecked Sendable {
    private var iterator: AsyncThrowingStream<Data, Failure>.AsyncIterator
    private let onTermination: (@Sendable () -> Void)?

    init(
        stream: AsyncThrowingStream<Data, Failure>,
        onTermination: (@Sendable () -> Void)? = nil
    ) {
        self.iterator = stream.makeAsyncIterator()
        self.onTermination = onTermination
    }

    func next() async throws -> Data? {
        try await iterator.next()
    }

    deinit {
        onTermination?()
    }
}
