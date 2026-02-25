// FulcrumNetworkClient~FulcrumRequest.swift

import Foundation

extension FulcrumNetworkClient {
    func call<ResultModel: JSONRPCResponse>(
        method: FulcrumMethodRequest,
        options: CallModel.OptionsModel = .init(),
        suppressTransportLogging: Bool = false
    ) async throws -> (UUID, ResultModel) {
        if method.isSubscription {
            throw FulcrumClient.Error.client(
                .protocolMismatch("call() cannot be used with subscription methods. Use subscribe(...) instead.")
            )
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        
        if suppressTransportLogging {
            await transport.registerQuietResponse(for: id)
        }
        
        let callTask = Task<Data, Swift.Error> { try await executeUnaryRequest(id: id, request: request) }
        
        if let token = options.token {
            await token.register { [weak self] in
                Task {
                    callTask.cancel()
                    guard let self else { return }
                    await self.cancelUnary(id, error: FulcrumClient.Error.client(.cancelled))
                }
            }
        }
        
        if let token = options.token, await token.isCancelled {
            callTask.cancel()
            await self.cancelUnary(id, error: FulcrumClient.Error.client(.cancelled))
            throw FulcrumClient.Error.client(.cancelled)
        }
        
        let raw: Data
        if let limit = options.timeout {
            raw = try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask { try await callTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    callTask.cancel()
                    await self.cancelUnary(id)
                    throw FulcrumClient.Error.client(.timeout(limit))
                }
                
                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        } else {
            raw = try await callTask.value
        }
        
        return try (id, raw.decode(ResultModel.self, context: .init(methodPath: method.path)))
    }
    
    func subscribe<Initial: JSONRPCResponse, Notification: JSONRPCResponse>(
        method: FulcrumMethodRequest,
        options: CallModel.OptionsModel = .init()
    ) async throws -> (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>) {
        if !method.isSubscription {
            throw FulcrumClient.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use submit(...) for unary calls.")
            )
        }
        
        guard let subscriptionPath = method.subscriptionPath else {
            throw FulcrumClient.Error.client(.protocolMismatch("subscribe() requires supported subscription methods."))
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKeyModel(
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
                    
                    let initialRawStream = try await registerUnaryResponse(for: id)
                    
                    try Task.checkCancellation()
                    try await send(request: request)
                    
                    let initialRaw = try await awaitUnaryResponse(from: initialRawStream)
                    let initial = try initialRaw.decode(
                        Initial.self,
                        context: .init(methodPath: method.path)
                    )
                    
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
                        await self.cleanUpSubscriptionSetup(
                            for: subscriptionKey,
                            requestIdentifier: id,
                            error: FulcrumClient.Error.client(.cancelled)
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
                    subscriptionTask.cancel()
                    guard let self else { return }
                    let cleanupKey = SubscriptionKeyModel(
                        methodPath: subscriptionPath,
                        identifier: subscriptionKey.identifier
                    )
                    await self.cleanUpSubscriptionSetup(
                        for: cleanupKey,
                        requestIdentifier: idCopy,
                        error: FulcrumClient.Error.client(.cancelled)
                    )
                }
            }
        }
        
        if let token = options.token, await token.isCancelled {
            subscriptionTask.cancel()
            await self.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: id,
                error: FulcrumClient.Error.client(.cancelled)
            )
            throw FulcrumClient.Error.client(.cancelled)
        }
        
        if let limit = options.timeout {
            return try await withThrowingTaskGroup(
                of: (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>).self
            ) { group in
                group.addTask { try await subscriptionTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    subscriptionTask.cancel()
                    await self.cleanUpSubscriptionSetup(
                        for: subscriptionKey,
                        requestIdentifier: id,
                        error: FulcrumClient.Error.client(.timeout(limit))
                    )
                    throw FulcrumClient.Error.client(.timeout(limit))
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
