// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    /// Regular Request
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type// = RegularResponseResult.self
    ) async throws -> (UUID,
                       RegularResponseResult) {
        let requestID = UUID()
        let request = method.createRequest(with: requestID)
        guard let payload = request.data else { throw Error.coding(.encode(nil)) }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await self.client.insertRegularHandler(for: requestID) { @Sendable result in
                        defer { Task { await self.client.removeRegularResponseHandler(for: requestID) } }
                        
                        switch result {
                        case .success(let payload):
                            continuation.resume(with: Result(catching: { (requestID, try payload.decode(RegularResponseResult.self)) }))
                        case .failure(let error):
                            continuation.resume(throwing: Error.client(.unknown(error)))
                        }
                    }
                    try await self.client.send(data: payload)
                } catch {
                    await self.client.removeRegularResponseHandler(for: requestID)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Subscription Request
    public func submit<SubscriptionNotification: JSONRPCConvertible>(
        method: Method,
        notificationType: SubscriptionNotification.Type// = SubscriptionNotification.self
    ) async throws -> (UUID,
                       SubscriptionNotification,
                       AsyncThrowingStream<SubscriptionNotification, Swift.Error>) {
        let requestID = UUID()
        let request = method.createRequest(with: requestID)
        guard let payload = request.data else { throw Error.coding(.encode(nil)) }
        let subscriptionKey = await Client.SubscriptionKey(methodPath: request.method,
                                                           identifier: self.client.getSubscriptionIdentifier(for: method))
        
        let initialResponse: SubscriptionNotification = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await self.client.insertRegularHandler(for: requestID) { @Sendable result in
                        defer { Task { await self.client.removeRegularResponseHandler(for: requestID) } }
                        
                        switch result {
                        case .success(let payload):
                            continuation.resume(with: Result(catching: { try payload.decode(SubscriptionNotification.self) }))
                        case .failure(let error):
                            continuation.resume(throwing: Error.client(.unknown(error)))
                        }
                    }
                    try await self.client.send(data: payload)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let (notificationStream, continuation) = AsyncThrowingStream<SubscriptionNotification, Swift.Error>.makeStream()

        try await self.client.insertSubscriptionHandler(for: subscriptionKey) { @Sendable result in
            switch result {
            case .success(let payload):
                do {
                    continuation.yield(try payload.decode(SubscriptionNotification.self))
                } catch {
                    continuation.finish(throwing: error)
                }
            case .failure(let error):
                continuation.finish(throwing: Error.client(.unknown(error)))
            }
        }

        continuation.onTermination = { @Sendable _ in
            Task {
                await self.client.removeSubscriptionResponseHandler(for: subscriptionKey)
                // TODO: actually send "unsubscribe"
            }
        }
        
        return (requestID, initialResponse, notificationStream)
    }
}
