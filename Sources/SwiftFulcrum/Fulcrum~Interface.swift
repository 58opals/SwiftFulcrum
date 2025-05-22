// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    /// Regular Request
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type // = RegularResponseResult.self
    ) async throws -> RegularResponseResult {
        let rpc: RegularResponseResult.JSONRPC = try await self.client.call(method: method)
        return try RegularResponseResult(fromRPC: rpc)
    }

    /// Subscription Request
    public func submit<SubscriptionNotification: JSONRPCConvertible>(
        method: Method,
        notificationType: SubscriptionNotification.Type // = SubscriptionNotification.self
    ) async throws -> (SubscriptionNotification,
                       AsyncThrowingStream<SubscriptionNotification, Swift.Error>) {
        let (initialRPC, rpcStream) = try await self.client.subscribe(method: method)
        let initial = try SubscriptionNotification(fromRPC: initialRPC)

        let mappedStream = AsyncThrowingStream<SubscriptionNotification, Swift.Error> { continuation in
            Task {
                do {
                    for try await rpc in rpcStream {
                        continuation.yield(try SubscriptionNotification(fromRPC: rpc))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return (initial, mappedStream)
    }
}
