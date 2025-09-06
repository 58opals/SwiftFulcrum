// Client~Request.swift

import Foundation

extension Client {
    func call<Result: JSONRPCConvertible>(
        method: Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, Result) {
        let id = UUID()
        let request = method.createRequest(with: id)
        
        let callTask = Task<Data, Swift.Error> {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
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
                }
            } onCancel: {
                Task { await self.router.cancel(identifier: .uuid(id)) }
            }
        }
        
        if let token = options.token {
            await token.register { callTask.cancel() }
        }
        
        let raw: Data
        if let limit = options.timeout {
            raw = try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask { try await callTask.value }
                group.addTask {
                    try await Task.sleep(for: limit)
                    callTask.cancel()
                    throw Fulcrum.Error.client(.timeout(limit))
                }
                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        } else {
            raw = try await callTask.value
        }
        
        return try (id, raw.decode(Result.self))
    }
    
    func subscribe<Result: JSONRPCConvertible>(
        method: Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, Result, AsyncThrowingStream<Result, Swift.Error>) {
        let id = UUID()
        let request = method.createRequest(with: id)
        let subscriptionKey = SubscriptionKey(
            methodPath: method.path,
            identifier: getSubscriptionIdentifier(for: method)
        )
        
        let subscriptionTask = Task<(UUID, Result, AsyncThrowingStream<Result, Swift.Error>), Swift.Error> {
            try await withTaskCancellationHandler {
                let (rawStream, rawContinuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
                
                try await router.addStream(
                    key: subscriptionKey.string,
                    continuation: rawContinuation
                )
                subscriptionMethods[subscriptionKey] = method
                
                rawContinuation.onTermination = { @Sendable [weak self] _ in
                    guard let self else { return }
                    
                    Task {
                        await self.router.cancel(identifier: .uuid(id))
                        await self.router.cancel(identifier: .string(subscriptionKey.string))
                        await self.removeStoredSubscriptionMethod(for: subscriptionKey)
                        
                        if let method = await self.makeUnsubscribeMethod(for: subscriptionKey) {
                            let request = method.createRequest(with: UUID())
                            try? await self.send(request: request)
                        }
                    }
                }
                
                let initial: Result = try await withCheckedThrowingContinuation { continuation in
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
                
                return (id, initial, typedStream)
            } onCancel: {
                Task {
                    await self.router.cancel(identifier: .uuid(id))
                    await self.router.cancel(identifier: .string(subscriptionKey.string))
                }
            }
        }
        
        if let token = options.token {
            let idCopy = id
            let keyCopy = subscriptionKey.string
            let router = self.router
            await token.register { @Sendable in
                Task {
                    await router.cancel(identifier: .uuid(idCopy))
                    await router.cancel(identifier: .string(keyCopy))
                }
            }
        }
        
        if let limit = options.timeout {
            return try await withThrowingTaskGroup(of: (UUID, Result, AsyncThrowingStream<Result, Swift.Error>).self) { group in
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
        guard let data = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
        try await self.send(data: data)
    }
}
