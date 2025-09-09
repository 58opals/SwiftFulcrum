// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self,
        options: Client.Call.Options = .init()
    ) async throws -> RPCResponse<RegularResponseResult, Never> {
        let (id, result): (UUID, RegularResponseResult) = try await client.call(method: method, options: options)
        return .single(id: id, result: result)
    }
    
    public func submit<SubscriptionNotification: JSONRPCConvertible>(
        method: Method,
        notificationType: SubscriptionNotification.Type = SubscriptionNotification.self,
        options: Client.Call.Options = .init()
    ) async throws -> RPCResponse<SubscriptionNotification, SubscriptionNotification> {
        let token = options.token ?? Client.Call.Token()
        let effectiveOptions = Client.Call.Options(timeout: options.timeout, token: token)
        let (id, initial, updates): (UUID, SubscriptionNotification, AsyncThrowingStream<SubscriptionNotification, Swift.Error>) = try await client.subscribe(method: method, options: effectiveOptions)
        return .stream(
            id: id,
            initialResponse: initial,
            updates: updates,
            cancel: { await token.cancel() }
        )
    }
}
