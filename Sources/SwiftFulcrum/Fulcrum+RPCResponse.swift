// Fulcrum+RPCResponse.swift

import Foundation

extension Fulcrum {
    public struct RPCSingleResponse {}
    public struct RPCStreamResponse {}
}

extension Fulcrum {
    public enum RPCResponse<Single: Sendable, Stream: Sendable>: Sendable {
        case single(id: UUID,
                    result: Single)
        case stream(id: UUID,
                    initialResponse: Single,
                    updates: AsyncThrowingStream<Stream, Swift.Error>,
                    cancel: @Sendable () async -> Void)

        public func extractRegularResponse() -> (Single)? {
            guard case .single(let id, let result) = self else { return nil }
            _ = id
            return result
        }
        
        public func extractSubscriptionStream() -> (Single, AsyncThrowingStream<Stream, Swift.Error>, @Sendable () async -> Void)? {
            guard case .stream(let id, let initialResponse, let updates, let cancel) = self else { return nil }
            _ = id
            return (initialResponse, updates, cancel)
        }
    }
}
