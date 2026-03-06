import Foundation

final class DataStreamIteratorModel<Failure: Swift.Error>: @unchecked Sendable {
    private var iterator: AsyncThrowingStream<Data, Failure>.AsyncIterator

    init(stream: AsyncThrowingStream<Data, Failure>) {
        self.iterator = stream.makeAsyncIterator()
    }

    func next() async throws -> Data? {
        try await iterator.next()
    }
}
