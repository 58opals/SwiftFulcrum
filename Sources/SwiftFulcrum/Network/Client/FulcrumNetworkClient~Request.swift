// FulcrumNetworkClient~Request.swift

import Foundation

extension FulcrumNetworkClient {
    func call<ResponsePayload: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: Call.Options = .init(),
        suppressTransportLogging: Bool = false
    ) async throws -> (UUID, ResponsePayload) {
        if method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("call() cannot be used with subscription methods. Use subscribe(...) instead.")
            )
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let timeoutState = RequestTimeoutState()
        
        if suppressTransportLogging {
            await transport.registerQuietResponse(for: id)
        }
        
        let callTask = Task<Data, Swift.Error> {
            try await executeUnaryRequest(id: id, request: request, timeoutState: timeoutState)
        }
        
        if let token = options.token {
            await token.register { [weak self] in
                callTask.cancel()
                guard let self else { return }
                await self.cancelUnary(id, error: SwiftFulcrum.Client.Error.client(.cancelled))
            }
        }
        
        if let token = options.token, await token.isCancelled {
            callTask.cancel()
            await self.cancelUnary(id, error: SwiftFulcrum.Client.Error.client(.cancelled))
            throw SwiftFulcrum.Client.Error.client(.cancelled)
        }
        
        let raw: Data
        if let limit = options.timeout {
            let timeoutError = SwiftFulcrum.Client.Error.client(.timeout(limit))
            raw = try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask { try await callTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    await timeoutState.mark(timeoutError)
                    callTask.cancel()
                    await self.cancelUnary(id, error: timeoutError)
                    throw timeoutError
                }
                
                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        } else {
            raw = try await callTask.value
        }
        
        return try (id, raw.decode(ResponsePayload.self, context: .init(methodPath: method.path)))
    }
    
    func subscribe<Initial: Decodable & Sendable, Notification: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>) {
        if !method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use request(...) for unary calls.")
            )
        }
        
        guard let subscriptionPath = method.subscriptionPath else {
            throw SwiftFulcrum.Client.Error.client(.protocolMismatch("subscribe() requires supported subscription methods."))
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKey(
            methodPath: subscriptionPath,
            identifier: deriveSubscriptionIdentifier(for: method)
        )
        let timeoutState = RequestTimeoutState()
        
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
                    
                    let initialRawStream = try await registerUnaryResponse(for: id)
                    
                    try Task.checkCancellation()
                    try await send(request: request)
                    
                    let initialRaw = try await awaitUnaryResponse(from: initialRawStream)
                    let initial = try initialRaw.decode(
                        Initial.self,
                        context: .init(methodPath: method.path)
                    )
                    clearSubscriptionSetupRequestIdentifier(id, for: subscriptionKey)
                    
                    let decodedStream = rawStream.decode(
                        Notification.self,
                        context: .init(methodPath: method.path)
                    )
                    let typedStream = AsyncThrowingStream<Notification, Swift.Error> { continuation in
                        Task {
                            do {
                                for try await value in decodedStream {
                                    if case .terminated = continuation.yield(value) {
                                        break
                                    }
                                }
                                continuation.finish()
                            } catch {
                                continuation.finish(throwing: error)
                            }
                        }
                        
                        continuation.onTermination = { @Sendable _ in
                            rawContinuation.finish()
                        }
                    }
                    
                    return (id, initial, typedStream)
                } onCancel: {
                    Task {
                        let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                        await self.cleanUpSubscriptionSetup(
                            for: subscriptionKey,
                            requestIdentifier: id,
                            error: cancellationError
                        )
                    }
                }
            } catch {
                let resolvedError: Swift.Error
                if error is CancellationError {
                    resolvedError = await makeRequestCancellationError(using: timeoutState)
                } else {
                    resolvedError = error
                }
                await self.cleanUpSubscriptionSetup(
                    for: subscriptionKey,
                    requestIdentifier: id,
                    error: resolvedError
                )
                throw resolvedError
            }
        }
        
        if let token = options.token {
            let idCopy = id
            await token.register { [weak self] in
                subscriptionTask.cancel()
                guard let self else { return }
                let cleanupKey = SubscriptionKey(
                    methodPath: subscriptionPath,
                    identifier: subscriptionKey.identifier
                )
                await self.scheduleSubscriptionCleanup(
                    for: cleanupKey,
                    requestIdentifier: idCopy,
                    error: SwiftFulcrum.Client.Error.client(.cancelled)
                )
            }
        }
        
        if let token = options.token, await token.isCancelled {
            subscriptionTask.cancel()
            await self.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: id,
                error: SwiftFulcrum.Client.Error.client(.cancelled)
            )
            throw SwiftFulcrum.Client.Error.client(.cancelled)
        }
        
        if let limit = options.timeout {
            let timeoutError = SwiftFulcrum.Client.Error.client(.timeout(limit))
            return try await withThrowingTaskGroup(
                of: (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>).self
            ) { group in
                group.addTask { try await subscriptionTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    await timeoutState.mark(timeoutError)
                    subscriptionTask.cancel()
                    await self.cleanUpSubscriptionSetup(
                        for: subscriptionKey,
                        requestIdentifier: id,
                        error: timeoutError
                    )
                    throw timeoutError
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
