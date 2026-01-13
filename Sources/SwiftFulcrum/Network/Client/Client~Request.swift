// Client~Request.swift

import Foundation

extension Client {
    func call<Result: JSONRPCConvertible>(
        method: Method,
        options: Call.Options = .init(),
        suppressTransportLogging: Bool = false
    ) async throws -> (UUID, Result) {
        if method.isSubscription {
            throw Fulcrum.Error.client(
                .protocolMismatch("call() cannot be used with subscription methods. Use subscribe(...) instead.")
            )
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        
        if suppressTransportLogging {
            await transport.registerQuietResponse(for: id)
        }
        
        if let token = options.token {
            await token.register { [weak self] in
                Task {
                    guard let self else { return }
                    let inflightCount = await self.router.cancel(identifier: .uuid(id))
                    await self.publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                }
            }
        }
        
        if let token = options.token, await token.isCancelled {
            let inflightCount = await router.cancel(identifier: .uuid(id))
            await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
            throw Fulcrum.Error.client(.cancelled)
        }
        
        let callTask = Task<Data, Swift.Error> {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    Task {
                        do {
                            let inflightCount = try await router.addUnary(id: id, continuation: continuation)
                            await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                        } catch {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        do {
                            try await send(request: request)
                        } catch {
                            let inflightCount = await router.cancel(identifier: .uuid(id), error: error)
                            await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                        }
                    }
                }
            } onCancel: {
                Task {
                    let inflightCount = await self.router.cancel(identifier: .uuid(id))
                    await self.publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                }
            }
        }
        
        
        let raw: Data
        if let limit = options.timeout {
            raw = try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask { try await callTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    callTask.cancel()
                    let inflightCount = await self.router.cancel(identifier: .uuid(id))
                    await self.publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                    throw Fulcrum.Error.client(.timeout(limit))
                }
                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        } else {
            raw = try await callTask.value
        }
        
        return try (id, raw.decode(Result.self, context: .init(methodPath: method.path)))
    }
    
    func subscribe<Initial: JSONRPCConvertible, Notification: JSONRPCConvertible>(
        method: Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>) {
        if !method.isSubscription {
            throw Fulcrum.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use submit(...) for unary calls.")
            )
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKey(
            methodPath: method.path,
            identifier: deriveSubscriptionIdentifier(for: method)
        )
        
        let subscriptionTask = Task<(UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>), Swift.Error> {
            do {
                return try await withTaskCancellationHandler {
                    let (rawStream, rawContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
                    
                    try await router.addStream(
                        key: subscriptionKey.string,
                        continuation: rawContinuation
                    )
                    subscriptionMethods[subscriptionKey] = method
                    
                    emitLog(.info,
                            "subscription_registry.added",
                            metadata: [
                                "identifier": subscriptionKey.identifier ?? "",
                                "method": method.path,
                                "subscriptionCount": String(subscriptionMethods.count)
                            ]
                    )
                    await publishSubscriptionRegistry()
                    await publishDiagnosticsSnapshot()
                    
                    rawContinuation.onTermination = { @Sendable [weak self] _ in
                        guard let self else { return }
                        
                        Task {
                            let removed = await self.cleanUpSubscriptionSetup(
                                for: subscriptionKey,
                                requestIdentifier: id
                            )
                            
                            if removed, let method = await self.makeUnsubscribeMethod(for: subscriptionKey) {
                                let request = method.createRequest(with: UUID())
                                try? await self.send(request: request)
                            }
                        }
                    }
                    let initial: Initial = try await withCheckedThrowingContinuation { continuation in
                        Task {
                            do {
                                let inflightCount = try await router.addUnary(id: id, continuation: continuation)
                                await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
                            } catch {
                                continuation.resume(throwing: error)
                                return
                            }
                            
                            do {
                                try await send(request: request)
                            } catch {
                                await self.cleanUpSubscriptionSetup(
                                    for: subscriptionKey,
                                    requestIdentifier: id,
                                    error: error
                                )
                            }
                        }
                    }.decode(
                        Initial.self,
                        context: .init(methodPath: method.path)
                    )
                    
                    let typedStream: AsyncThrowingStream<Notification, Swift.Error> = rawStream.decode(Notification.self, context: .init(methodPath: method.path))
                    
                    return (id, initial, typedStream)
                } onCancel: {
                    Task {
                        await self.cleanUpSubscriptionSetup(
                            for: subscriptionKey,
                            requestIdentifier: id
                        )
                    }
                }
            } catch {
                await self.cleanUpSubscriptionSetup(
                    for: subscriptionKey,
                    requestIdentifier: id,
                    error: error
                )
                throw error
            }
        }
        
        if let token = options.token {
            let idCopy = id
            await token.register { [weak self] in
                Task {
                    guard let self else { return }
                    let cleanupKey = SubscriptionKey(methodPath: method.path, identifier: subscriptionKey.identifier)
                    await self.cleanUpSubscriptionSetup(
                        for: cleanupKey,
                        requestIdentifier: idCopy,
                        error: Fulcrum.Error.client(.cancelled)
                    )
                }
            }
        }
        
        if let limit = options.timeout {
            return try await withThrowingTaskGroup(of: (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>).self) { group in
                group.addTask { try await subscriptionTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    subscriptionTask.cancel()
                    throw Fulcrum.Error.client(.timeout(limit))
                }
                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        } else {
            return try await subscriptionTask.value
        }
    }
}

extension Client {
    func send(request: Request) async throws {
        if case .server(.version) = request.requestedMethod {
            guard let data = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
            try await self.send(data: data)
            return
        }
        
        _ = try await ensureNegotiatedProtocol()
        
        guard let data = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
        try await self.send(data: data)
    }
}
