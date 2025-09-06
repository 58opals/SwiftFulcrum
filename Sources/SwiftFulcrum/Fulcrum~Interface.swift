// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self
    ) async throws -> RPCResponse<RegularResponseResult, Never> {
        let (id, result): (UUID, RegularResponseResult) = try await client.call(method: method)
        return .single(id: id, result: result)
    }
    
    public func submit<SubscriptionNotification: JSONRPCConvertible>(
        method: Method,
        notificationType: SubscriptionNotification.Type = SubscriptionNotification.self
    ) async throws -> RPCResponse<SubscriptionNotification, SubscriptionNotification> {
        let token = Client.Call.Token()
        let (id, initial, updates): (UUID, SubscriptionNotification, AsyncThrowingStream<SubscriptionNotification, Swift.Error>) = try await client.subscribe(method: method, options: .init(token: token))
        return .stream(
            id: id,
            initialResponse: initial,
            updates: updates,
            cancel: { await token.cancel() }
        )
    }
}
