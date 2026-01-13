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
                    await self.cancelUnary(id)
                }
            }
        }
        
        if let token = options.token, await token.isCancelled {
            await self.cancelUnary(id)
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
                            await cancelUnary(id, error: error)
                        }
                    }
                }
            } onCancel: {
                Task {
                    await self.cancelUnary(id)
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
                    await self.cancelUnary(id)
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
        
        guard let subscriptionPath = method.subscriptionPath else {
            throw Fulcrum.Error.client(.protocolMismatch("subscribe() requires supported subscription methods."))
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKey(
            methodPath: subscriptionPath,
            identifier: deriveSubscriptionIdentifier(for: method)
        )
        
        let subscriptionTask = Task<(UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>), Swift.Error> {
            do {
                return try await withTaskCancellationHandler {
                    let (rawStream, rawContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
                    
                    try await configureSubscriptionLifecycle(
                        rawContinuation: rawContinuation,
                        subscriptionKey: subscriptionKey,
                        method: method,
                        requestIdentifier: id
                    )
                    
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
                    let cleanupKey = SubscriptionKey(
                        methodPath: subscriptionPath,
                        identifier: subscriptionKey.identifier
                    )
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
    
    private func cancelUnary(_ id: UUID, error: Swift.Error? = nil) async {
        let inflight = await router.cancel(identifier: .uuid(id), error: error)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflight)
    }
}
