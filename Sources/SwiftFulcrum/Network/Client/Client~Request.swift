// Client~Request.swift

import Foundation

extension Client {
    func call<Result: Decodable>(method: Method) async throws -> Result {
        let id = UUID()
        let request = method.createRequest(with: id)
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await router.addUnary(id: id, continuation: continuation)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                do {
                    try await send(request: request)
                } catch {
                    await router.cancel(identifier: .uuid(id), error: error)
                }
            }
        }.decode(Result.self)
    }
    
    func subscribe<Result: Decodable>(method: Method) async throws -> (UUID, Result, AsyncThrowingStream<Result, Swift.Error>) {
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKey(methodPath: method.path,
                                              identifier: getSubscriptionIdentifier(for: method))
        
        let (rawStream, rawContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        
        try await router.addStream(key: subscriptionKey.string, continuation: rawContinuation)
        subscriptionMethods[subscriptionKey] = method
        
        rawContinuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }
            
            Task {
                await self.router.cancel(identifier: .string(subscriptionKey.string))
                await self.removeSubscriptionResponseHandler(for: subscriptionKey)
                await self.removeStoredSubscriptionMethod(for: subscriptionKey)
                
                if let method = await self.makeUnsubscribeMethod(for: subscriptionKey) {
                    _ = try? await self.sendRegularRequest(method: method) { _ in }
                }
            }
        }
        
        let initialResponse: Result = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await router.addUnary(id: id, continuation: continuation)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                do {
                    try await send(request: request)
                } catch {
                    await router.cancel(identifier: .uuid(id), error: error)
                    await router.cancel(identifier: .string(subscriptionKey.string), error: error)
                }
            }
        }.decode(Result.self)
        
        let typedStream = rawStream.decode(Result.self)
        
        return (id, initialResponse, typedStream)
    }
}

extension Client {
    func sendRegularRequest(method: Method,
                            handler: @escaping RegularResponseHandler) async throws -> RegularResponseIdentifier {
        let requestID: UUID = .init()
        let request: Request = method.createRequest(with: requestID)
        
        try insertRegularHandler(for: requestID, handler: handler)
        
        do {
            try await send(request: request)
        } catch {
            regularResponseHandlers.removeValue(forKey: requestID)
            throw error
        }
        
        return requestID
    }
    
    func sendSubscriptionRequest(method: Method,
                                 initialResponseHandler: @escaping RegularResponseHandler,
                                 notificationHandler: @escaping SubscriptionResponseHandler) async throws -> SubscriptionToken {
        let requestID: UUID = .init()
        let request: Request = method.createRequest(with: requestID)
        let subscriptionKey = SubscriptionResponseIdentifier(methodPath: request.method,
                                                             identifier: getSubscriptionIdentifier(for: method))
        
        try insertRegularHandler(for: requestID, handler: initialResponseHandler)
        try insertSubscriptionHandler(for: subscriptionKey, handler: notificationHandler)
        subscriptionMethods[subscriptionKey] = method
        
        do {
            try await send(request: request)
        } catch {
            regularResponseHandlers.removeValue(forKey: requestID)
            subscriptionResponseHandlers.removeValue(forKey: subscriptionKey)
            throw error
        }
        
        let cancelClosure: @Sendable () async -> Void = { [weak self] in
            guard let self else { return }
            
            await self.removeSubscriptionResponseHandler(for: subscriptionKey)
            await self.removeStoredSubscriptionMethod(for: subscriptionKey)
            
            if let method = await self.makeUnsubscribeMethod(for: subscriptionKey) {
                _ = try? await self.sendRegularRequest(method: method) { _ in }
            }
        }
        
        return .init(requestID: requestID, key: subscriptionKey, cancelClosure: cancelClosure)
    }
    
    func send(request: Request) async throws {
        guard let data = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
        try await self.send(data: data)
    }
}
