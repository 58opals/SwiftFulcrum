// Client~InterfaceSupport.swift

import Foundation

extension SwiftFulcrum.Client {
    typealias TimeoutDeadline = (limit: Duration, instant: ContinuousClock.Instant)

    func makeSubscription<Initial: Decodable & Sendable, Update: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: SwiftFulcrum.Client.Call.Options,
        deadline: TimeoutDeadline?,
        observedStopGeneration: UInt64
    ) async throws -> Subscription<Initial, Update> {
        if !method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use request(...) for unary calls.")
            )
        }

        try await prepareClientForRequests(
            until: deadline,
            observedStopGeneration: observedStopGeneration
        )

        let token = FulcrumNetworkClient.Call.Token()
        let callerCancellationToken = options.cancellation?.token
        let callerCancellationRegistrationID = await callerCancellationToken?.register {
            await token.cancel()
        }
        do {
            let effectiveOptions = try FulcrumNetworkClient.Call.Options(
                timeout: remainingTimeout(until: deadline),
                token: token,
                subscriptionBufferPolicy: options.subscriptionBufferPolicy
            )
            try ensureRequestPreparationIsCurrent(
                observedStopGeneration: observedStopGeneration
            )
            let (_, initial, updates): (UUID, Initial, AsyncThrowingStream<Update, Swift.Error>) =
                try await client.subscribe(method: method, options: effectiveOptions)
            if let callerCancellationToken, let callerCancellationRegistrationID {
                await callerCancellationToken.unregister(callerCancellationRegistrationID)
            }
            let cancellationState = SubscriptionUpdatesCancellationState {
                await token.cancel()
            }
            return Subscription(
                initial: initial,
                updates: .init(stream: updates, cancellationState: cancellationState)
            )
        } catch {
            if let callerCancellationToken, let callerCancellationRegistrationID {
                await callerCancellationToken.unregister(callerCancellationRegistrationID)
            }
            throw adaptClientFacingError(error, originalLimit: deadline?.limit)
        }
    }

    func makeDeadline(for limit: Duration?) throws -> TimeoutDeadline? {
        guard let limit else { return nil }
        let maximumLimit = Duration.seconds(
            SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds
        )
        guard limit > .zero, limit <= maximumLimit else {
            throw SwiftFulcrum.Client.Error.client(
                .invalidConfiguration(
                    "Call timeout must be greater than zero and no more than "
                        + "\(SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds) seconds."
                )
            )
        }

        let clock = ContinuousClock()
        return (limit: limit, instant: clock.now.advanced(by: limit))
    }

    func makeClientOptions(
        from options: SwiftFulcrum.Client.Call.Options,
        constrainedBy deadline: TimeoutDeadline?
    ) throws -> FulcrumNetworkClient.Call.Options {
        .init(timeout: try remainingTimeout(until: deadline), token: options.cancellation?.token)
    }

    func remainingTimeout(until deadline: TimeoutDeadline?) throws -> Duration? {
        guard let deadline else { return nil }
        return try remainingTimeoutBefore(deadline)
    }

    func remainingTimeoutBefore(_ deadline: TimeoutDeadline) throws -> Duration {
        let now = ContinuousClock().now
        let remaining = now.duration(to: deadline.instant)

        guard remaining > .zero else {
            throw SwiftFulcrum.Client.Error.client(.timeout(deadline.limit))
        }

        return remaining
    }

    func executeBeforeDeadline<T: Sendable>(
        _ deadline: TimeoutDeadline?,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        guard let deadline else {
            return try await operation()
        }

        do {
            return try await executeWithTimeout(
                limit: remainingTimeoutBefore(deadline),
                operation: operation
            )
        } catch let fulcrumError as SwiftFulcrum.Client.Error {
            throw remapTimeoutErrorIfNeeded(fulcrumError, originalLimit: deadline.limit)
        }
    }

    func remapTimeoutErrorIfNeeded(
        _ error: SwiftFulcrum.Client.Error,
        originalLimit: Duration?
    ) -> SwiftFulcrum.Client.Error {
        guard let originalLimit else { return error }

        if case .client(.timeout) = error {
            return .client(.timeout(originalLimit))
        }

        return error
    }

    func adaptClientFacingError(
        _ error: Swift.Error,
        originalLimit: Duration?
    ) -> SwiftFulcrum.Client.Error {
        let fulcrumError: SwiftFulcrum.Client.Error
        if let fulcrumErrorValue = error as? SwiftFulcrum.Client.Error {
            fulcrumError = fulcrumErrorValue
        } else if error is ResponseResultDecodeError || error is JSONRPCResponseDecodeError || error is DecodingError {
            fulcrumError = .coding(.decode(error))
        } else {
            fulcrumError = .client(.unknown(error))
        }

        return remapTimeoutErrorIfNeeded(fulcrumError, originalLimit: originalLimit)
    }

    func executeWithTimeout<T: Sendable>(
        limit: Duration,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }

            group.addTask {
                try await Task.sleep(for: limit)
                throw SwiftFulcrum.Client.Error.client(.timeout(limit))
            }

            guard let result = try await group.next() else {
                throw CancellationError()
            }

            group.cancelAll()
            return result
        }
    }
}
