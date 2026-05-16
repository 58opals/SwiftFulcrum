// FulcrumNetworkClient~Request.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func call<ResponsePayload: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: Call.Options = .init()
    ) async throws -> (UUID, ResponsePayload) {
        if method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("call() cannot be used with subscription methods. Use subscribe(...) instead.")
            )
        }
        
        let id = UUID()
        let request = method.createRequest(with: id)
        let timeoutState = RequestTimeoutState()
        recordClientEvent(
            SwiftFulcrumDiagnostics.Event.clientCallBegin,
            traceID: SwiftFulcrumDiagnostics.traceID(for: id),
            fields: [SwiftFulcrumDiagnostics.methodField(method.path)]
        )
        
        let callTask = Task<Data, Swift.Error> {
            try await executeUnaryRequest(id: id, request: request, timeoutState: timeoutState)
        }
        let token = options.token
        let cancellationRegistrationID: FulcrumNetworkClient.Call.Token.RegistrationID?
        if let token {
            cancellationRegistrationID = await token.register { [weak self] in
                callTask.cancel()
                guard let self else { return }
                let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                await self.cancelUnary(id, error: cancellationError)
            }
        } else {
            cancellationRegistrationID = nil
        }

        let raw: Data
        do {
            raw = try await withTaskCancellationHandler {
                if let token, await token.isCancelled {
                    let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                    callTask.cancel()
                    await self.cancelUnary(id, error: cancellationError)
                    throw cancellationError
                }

                if let limit = options.timeout {
                    let timeoutError = SwiftFulcrum.Client.Error.client(.timeout(limit))
                    return try await withThrowingTaskGroup(of: Data.self) { group in
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
                }

                return try await callTask.value
            } onCancel: {
                callTask.cancel()
                Task {
                    let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                    await self.cancelUnary(id, error: cancellationError)
                }
            }
        } catch {
            if let token, let cancellationRegistrationID {
                await token.unregister(cancellationRegistrationID)
            }
            if error is CancellationError {
                let cancellationError = await makeRequestCancellationError(using: timeoutState)
                recordRequestFailure(
                    await callFailureEvent(for: cancellationError, timeoutState: timeoutState),
                    requestID: id,
                    methodPath: method.path,
                    error: cancellationError
                )
                throw cancellationError
            }
            recordRequestFailure(
                await callFailureEvent(for: error, timeoutState: timeoutState),
                requestID: id,
                methodPath: method.path,
                error: error
            )
            throw error
        }

        if let token, let cancellationRegistrationID {
            await token.unregister(cancellationRegistrationID)
        }

        do {
            let response = try raw.decode(ResponsePayload.self, context: .init(methodPath: method.path))
            recordClientEvent(
                SwiftFulcrumDiagnostics.Event.clientCallResponseDecoded,
                traceID: SwiftFulcrumDiagnostics.traceID(for: id),
                fields: [
                    SwiftFulcrumDiagnostics.methodField(method.path),
                    SwiftFulcrumDiagnostics.publicField("byte_count", raw.count)
                ]
            )
            return (id, response)
        } catch {
            recordRequestFailure(
                SwiftFulcrumDiagnostics.Event.clientCallFailed,
                requestID: id,
                methodPath: method.path,
                error: error
            )
            throw error
        }
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
        let token = options.token
        recordClientEvent(
            SwiftFulcrumDiagnostics.Event.clientSubscribeBegin,
            traceID: SwiftFulcrumDiagnostics.traceID(for: id),
            fields: [SwiftFulcrumDiagnostics.methodField(method.path)]
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
                    self.recordClientEvent(
                        SwiftFulcrumDiagnostics.Event.clientSubscribeInitialDecoded,
                        traceID: SwiftFulcrumDiagnostics.traceID(for: id),
                        fields: [
                            SwiftFulcrumDiagnostics.methodField(method.path),
                            SwiftFulcrumDiagnostics.publicField("byte_count", initialRaw.count)
                        ]
                    )
                    clearSubscriptionSetupRequestIdentifier(id, for: subscriptionKey)
                    
                    let typedStream = rawStream.decode(
                        Notification.self,
                        context: .init(methodPath: method.path),
                        onTermination: { @Sendable in
                            rawContinuation.finish()
                        }
                    )
                    
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
                let event = await self.subscribeFailureEvent(for: resolvedError, timeoutState: timeoutState)
                self.recordRequestFailure(
                    event,
                    requestID: id,
                    methodPath: method.path,
                    error: resolvedError
                )
                await self.cleanUpSubscriptionSetup(
                    for: subscriptionKey,
                    requestIdentifier: id,
                    error: resolvedError
                )
                throw resolvedError
            }
        }
        let cancellationRegistrationID: FulcrumNetworkClient.Call.Token.RegistrationID?
        if let token {
            cancellationRegistrationID = await token.register { [weak self] in
                subscriptionTask.cancel()
                guard let self else { return }
                let cleanupKey = SubscriptionKey(
                    methodPath: subscriptionPath,
                    identifier: subscriptionKey.identifier
                )
                let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                let shouldSendUnsubscribe = await self.shouldSendUnsubscribeOnCancellation(for: cleanupKey)
                Task {
                    _ = await self.scheduleSubscriptionCleanup(
                        for: cleanupKey,
                        requestIdentifier: id,
                        error: cancellationError,
                        sendUnsubscribe: shouldSendUnsubscribe,
                        preferCurrentSetupRequest: true
                    )
                }
            }
        } else {
            cancellationRegistrationID = nil
        }
        let cancellationRegistration: SubscriptionCancellationRegistration?
        if let token, let cancellationRegistrationID {
            cancellationRegistration = .init(token: token, registrationID: cancellationRegistrationID)
        } else {
            cancellationRegistration = nil
        }

        let subscriptionResult: (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>)
        do {
            subscriptionResult = try await withTaskCancellationHandler {
                if let token, await token.isCancelled {
                    let cancellationError = await self.makeRequestCancellationError(using: timeoutState)
                    subscriptionTask.cancel()
                    await self.cleanUpSubscriptionSetup(
                        for: subscriptionKey,
                        requestIdentifier: id,
                        error: cancellationError
                    )
                    throw cancellationError
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
                }

                return try await subscriptionTask.value
            } onCancel: {
                subscriptionTask.cancel()
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
            if let token, let cancellationRegistrationID {
                await token.unregister(cancellationRegistrationID)
            }
            if error is CancellationError {
                let cancellationError = await makeRequestCancellationError(using: timeoutState)
                recordRequestFailure(
                    await subscribeFailureEvent(for: cancellationError, timeoutState: timeoutState),
                    requestID: id,
                    methodPath: method.path,
                    error: cancellationError
                )
                throw cancellationError
            }
            throw error
        }

        await recordSubscriptionCancellationRegistration(cancellationRegistration, for: subscriptionKey)

        return subscriptionResult
    }
}

private extension FulcrumNetworkClient {
    func callFailureEvent(
        for error: Swift.Error,
        timeoutState: RequestTimeoutState
    ) async -> OpalDiagnostics.Event {
        if await timeoutState.timeoutError != nil || isTimeoutError(error) {
            return SwiftFulcrumDiagnostics.Event.clientCallTimeout
        }

        if isCancellationError(error) {
            return SwiftFulcrumDiagnostics.Event.clientCallCancelled
        }

        return SwiftFulcrumDiagnostics.Event.clientCallFailed
    }

    func subscribeFailureEvent(
        for error: Swift.Error,
        timeoutState: RequestTimeoutState
    ) async -> OpalDiagnostics.Event {
        if await timeoutState.timeoutError != nil || isTimeoutError(error) {
            return SwiftFulcrumDiagnostics.Event.clientSubscribeTimeout
        }

        if isCancellationError(error) {
            return SwiftFulcrumDiagnostics.Event.clientSubscribeCancelled
        }

        return SwiftFulcrumDiagnostics.Event.clientSubscribeFailed
    }

    func isCancellationError(_ error: Swift.Error) -> Bool {
        if error is CancellationError { return true }
        if let clientError = error as? SwiftFulcrum.Client.Error,
           clientError == .client(.cancelled) {
            return true
        }
        return false
    }

    func isTimeoutError(_ error: Swift.Error) -> Bool {
        if let clientError = error as? SwiftFulcrum.Client.Error,
           case .client(.timeout(_)) = clientError {
            return true
        }
        return false
    }
}
