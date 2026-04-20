// FulcrumNetworkClient.Router+PendingEntry.swift

import Foundation

extension FulcrumNetworkClient.Router {
    enum PendingEntry {
        case unary(AsyncThrowingStream<Data, Swift.Error>.Continuation)
        case stream(AsyncThrowingStream<Data, Swift.Error>.Continuation)
    }
}
