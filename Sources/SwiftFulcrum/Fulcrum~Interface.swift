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
        
        var pendingResult: Result<RegularResponseResult, Swift.Error>?
        var continuation: CheckedContinuation<(UUID, RegularResponseResult), Swift.Error>?

        try await self.client.insertRegularHandler(for: requestID) { @Sendable result in
            let processed: Result<(UUID, RegularResponseResult), Swift.Error> = result.flatMap { payload in
                Result { (requestID, try payload.decode(RegularResponseResult.self)) }
            }

            if let cont = continuation {
                cont.resume(with: processed)
            } else {
                pendingResult = processed.map { $0.1 }
            }

            Task { await self.client.removeRegularResponseHandler(for: requestID) }
        }

        try await withTaskCancellationHandler(operation: {
            try await self.client.send(data: payload)
        }, onCancel: {
            Task { await self.client.removeRegularResponseHandler(for: requestID) }
            continuation?.resume(throwing: CancellationError())
        })

        let response = try await withCheckedThrowingContinuation { cont in
            if let result = pendingResult {
                cont.resume(with: result.map { (requestID, $0) })
            } else {
                continuation = cont
            }
        }

        return response
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
        
        var pendingInitial: Result<SubscriptionNotification, Swift.Error>?
        var initialContinuation: CheckedContinuation<SubscriptionNotification, Swift.Error>?

        try await self.client.insertRegularHandler(for: requestID) { @Sendable result in
            let processed: Result<SubscriptionNotification, Swift.Error> = result.flatMap { payload in
                Result { try payload.decode(SubscriptionNotification.self) }
            }

            if let cont = initialContinuation {
                cont.resume(with: processed)
            } else {
                pendingInitial = processed
            }

            Task { await self.client.removeRegularResponseHandler(for: requestID) }
        }

        var streamContinuation: AsyncThrowingStream<SubscriptionNotification, Swift.Error>.Continuation!
        let notificationStream = AsyncThrowingStream<SubscriptionNotification, Swift.Error> { cont in
            streamContinuation = cont
            cont.onTermination = { @Sendable _ in
                Task { await self.client.removeSubscriptionResponseHandler(for: subscriptionKey) }
            }
        }

        try await self.client.insertSubscriptionHandler(for: subscriptionKey) { @Sendable result in
            switch result {
            case .success(let payload):
                do {
                    streamContinuation.yield(try payload.decode(SubscriptionNotification.self))
                } catch {
                    streamContinuation.finish(throwing: error)
                }
            case .failure(let error):
                streamContinuation.finish(throwing: Error.client(.unknown(error)))
            }
        }

        try await withTaskCancellationHandler(operation: {
            try await self.client.send(data: payload)
        }, onCancel: {
            Task {
                await self.client.removeRegularResponseHandler(for: requestID)
                await self.client.removeSubscriptionResponseHandler(for: subscriptionKey)
            }
            streamContinuation.finish(throwing: CancellationError())
            initialContinuation?.resume(throwing: CancellationError())
        })

        let initialResponse = try await withCheckedThrowingContinuation { cont in
            if let initial = pendingInitial {
                cont.resume(with: initial)
            } else {
                initialContinuation = cont
            }
        }

        return (requestID, initialResponse, notificationStream)
    }
}
