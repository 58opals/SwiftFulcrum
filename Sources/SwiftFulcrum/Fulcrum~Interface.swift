// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    /// Regular Request
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self
    ) async throws -> RPCResponse<RegularResponseResult, Never> {
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
                            continuation.resume(with: Result(catching: {
                                .single(id: requestID, result: try payload.decode(RegularResponseResult.self))
                            }))
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
        notificationType: SubscriptionNotification.Type = SubscriptionNotification.self
    ) async throws -> RPCResponse<SubscriptionNotification, SubscriptionNotification> {
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
        
        let terminationHandler: @Sendable () async -> Void = {
            await self.client.removeSubscriptionResponseHandler(for: subscriptionKey)
            
            guard let method = await self.client.makeUnsubscribeMethod(for: subscriptionKey) else { return }
            do {
                _ = try await self.client.sendRegularRequest(method: method) { result in
                    if case .failure(let error) = result {
                        Task { await self.client.failAllPendingRequests(with: Error.client(.unknown(error))) }
                    }
                }
            } catch {
                await self.client.failAllPendingRequests(with: Error.client(.unknown(error)))
            }
        }
        
        let notificationStream = AsyncThrowingStream<SubscriptionNotification, Swift.Error> { continuation in
            Task {
                do {
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
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { await terminationHandler() }
            }
        }
        
        let cancel: @Sendable () async -> Void = {
            await terminationHandler()
        }
        
        return .stream(id: requestID,
                       initialResponse: initialResponse,
                       updates: notificationStream,
                       cancel: cancel)
    }
}
