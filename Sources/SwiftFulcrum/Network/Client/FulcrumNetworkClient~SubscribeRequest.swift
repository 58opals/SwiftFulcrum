// FulcrumNetworkClient~SubscribeRequest.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
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
        let streamBufferingPolicy: AsyncThrowingStream<Data, Swift.Error>.Continuation.BufferingPolicy =
            try options.subscriptionBufferPolicy.makeBufferingPolicy()
        let subscriptionKey = SubscriptionKey(
            methodPath: subscriptionPath,
            identifier: deriveSubscriptionIdentifier(for: method)
        )
        let timeoutState = FulcrumNetworkClient.Call.TimeoutState()
        let token = options.token
        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientSubscribeBegin,
            level: .debug,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
            fields: makeRequestDiagnosticFields(methodPath: method.path)
        )

        let subscriptionTask = Task<(UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>), Swift.Error> {
            do {
                return try await withTaskCancellationHandler {
                    var rawContinuationStorage: AsyncThrowingStream<Data, Swift.Error>.Continuation!
                    let rawStream = AsyncThrowingStream<Data, Swift.Error>(
                        bufferingPolicy: streamBufferingPolicy
                    ) { continuation in
                        rawContinuationStorage = continuation
                    }
                    let rawContinuation = rawContinuationStorage!

                    try await configureSubscriptionLifecycle(
                        rawContinuation: rawContinuation,
                        subscriptionKey: subscriptionKey,
                        method: method,
                        requestIdentifier: id,
                        subscriptionBufferPolicy: options.subscriptionBufferPolicy
                    )

                    let initialRawStream = try await registerUnaryResponse(for: id)

                    try Task.checkCancellation()
                    try await send(request: request)

                    let initialRaw = try await awaitUnaryResponse(from: initialRawStream)
                    let initial = try initialRaw.decode(
                        Initial.self,
                        context: .init(methodPath: method.path)
                    )
                    OpalDiagnostics.logger(category: .fulcrum).record(
                        event: .swiftFulcrumClientSubscribeInitialDecoded,
                        level: .debug,
                        traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                        fields: self.makeRequestDiagnosticFields(methodPath: method.path, [
                            .swiftFulcrumField("byte_count", initialRaw.count)
                        ])
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
                            reason: .cancellation(cancellationError)
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
                OpalDiagnostics.logger(category: .fulcrum).record(
                    event: event,
                    level: .info,
                    traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                    fields: self.makeRequestFailureDiagnosticFields(methodPath: method.path, error: resolvedError)
                )
                await self.cleanUpSubscriptionSetup(
                    for: subscriptionKey,
                    requestIdentifier: id,
                    reason: .streamTermination(resolvedError)
                )
                throw resolvedError
            }
        }
        let executionContext = FulcrumNetworkClient.Call.ExecutionContext(
            task: subscriptionTask,
            token: token,
            timeout: options.timeout,
            timeoutState: timeoutState
        ) { [weak self] cancellationError in
            guard let self else { return }
            let cleanupKey = SubscriptionKey(
                methodPath: subscriptionPath,
                identifier: subscriptionKey.identifier
            )
            let shouldSendUnsubscribe = await self.shouldSendUnsubscribeOnCancellation(for: cleanupKey)
            _ = await self.scheduleSubscriptionCleanup(
                for: cleanupKey,
                requestIdentifier: id,
                reason: .cancellation(cancellationError),
                sendUnsubscribe: shouldSendUnsubscribe,
                scope: .currentSetupThenRequest
            )
        }

        let subscriptionResult: (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>)
        do {
            subscriptionResult = try await executionContext.value()
        } catch {
            if error is CancellationError {
                let cancellationError = await makeRequestCancellationError(using: timeoutState)
                OpalDiagnostics.logger(category: .fulcrum).record(
                    event: await subscribeFailureEvent(for: cancellationError, timeoutState: timeoutState),
                    level: .info,
                    traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: id),
                    fields: makeRequestFailureDiagnosticFields(methodPath: method.path, error: cancellationError)
                )
                throw cancellationError
            }
            throw error
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
                        reason: .cancellation(cancellationError),
                        sendUnsubscribe: shouldSendUnsubscribe,
                        scope: .currentSetupThenRequest
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
        await recordSubscriptionCancellationRegistration(cancellationRegistration, for: subscriptionKey)

        return subscriptionResult
    }
}
