// Client~Interface.swift

import Foundation

extension SwiftFulcrum.Client {
    /// Issues a unary JSON-RPC request and returns the decoded result payload.
    ///
    /// - Parameters:
    ///   - endpoint: Typed API endpoint to invoke.
    ///   - options: Optional timeout and cancellation controls. Cancelling the calling task cancels the request.
    /// - Returns: The decoded Fulcrum result model for the requested method.
    public func request<ResponsePayload: Decodable & Sendable>(
        _ endpoint: SwiftFulcrum.API.Request<ResponsePayload>,
        options: SwiftFulcrum.Client.Call.Options = .init()
    ) async throws -> ResponsePayload {
        let method = endpoint.method
        let cancellationToken = options.cancellation?.token
        try await throwIfCancelled(cancellationToken)
        let deadline = makeDeadline(for: options.timeout)
        try await prepareClientForRequests(until: deadline)
        try await throwIfCancelled(cancellationToken)
        
        do {
            let (_, result): (UUID, ResponsePayload) = try await client.call(
                method: method,
                options: try makeClientOptions(from: options, constrainedBy: deadline)
            )
            return result
        } catch {
            throw adaptClientFacingError(error, originalLimit: deadline?.limit)
        }
    }
    
    /// Starts a subscription and returns the initial response plus an update stream.
    ///
    /// - Parameters:
    ///   - endpoint: Typed subscription endpoint to invoke.
    ///   - options: Optional timeout and cancellation controls. Cancelling the calling task cancels the subscription setup.
    /// - Returns: A subscription wrapper containing the initial payload, the updates stream, and a cancellation handle.
    ///   Reconnect restore is best-effort, so downstream callers usually do not need to resubscribe
    ///   manually. If a restore is rejected, the affected updates stream terminates and requires a
    ///   fresh ``subscribe(...)`` call to resume.
    public func subscribe<Initial: Decodable & Sendable, Update: Decodable & Sendable>(
        _ endpoint: SwiftFulcrum.API.Subscription<Initial, Update>,
        options: SwiftFulcrum.Client.Call.Options = .init()
    ) async throws -> Subscription<Initial, Update> {
        try await throwIfCancelled(options.cancellation?.token)
        let deadline = makeDeadline(for: options.timeout)
        return try await makeSubscription(
            method: endpoint.method,
            options: options,
            deadline: deadline
        )
    }

    func request<RegularResponseResult: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self,
        options: SwiftFulcrum.Client.Call.Options = .init()
    ) async throws -> RegularResponseResult {
        if method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(.protocolMismatch("request() cannot be used with subscription methods. Use subscribe(...)."))
        }

        return try await request(
            SwiftFulcrum.API.Request<RegularResponseResult>(method: method),
            options: options
        )
    }

    func subscribe<Initial: Decodable & Sendable, Update: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        initial: Initial.Type = Initial.self,
        notifications: Update.Type = Update.self,
        options: SwiftFulcrum.Client.Call.Options = .init()
    ) async throws -> Subscription<Initial, Update> {
        if !method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use request(...) for unary calls.")
            )
        }

        return try await subscribe(
            SwiftFulcrum.API.Subscription<Initial, Update>(method: method),
            options: options
        )
    }
}

// MARK: -
extension SwiftFulcrum.Client {
    private typealias TimeoutDeadline = (limit: Duration, instant: ContinuousClock.Instant)

    private func throwIfCancelled(_ token: FulcrumNetworkClient.Call.Token?) async throws {
        guard let token, await token.isCancelled else { return }
        throw SwiftFulcrum.Client.Error.client(.cancelled)
    }
    
    private func prepareClientForRequests(until deadline: TimeoutDeadline?) async throws {
        if !isRunning {
            try await executeBeforeDeadline(deadline) {
                try await self.start()
            }
        }

        let state = await client.connectionState
        await updateConnectionState(state)

        switch state {
        case .connected:
            try await executeBeforeDeadline(deadline) {
                try await self.client.awaitReconnectReadiness()
            }
            return
        case .connecting:
            try await executeBeforeDeadline(deadline) {
                try await self.waitForClientConnectionToBecomeReady()
            }
        case .reconnecting:
            try await executeBeforeDeadline(deadline) {
                try await self.client.awaitReconnectReadiness()
            }
        case .idle:
            try await executeBeforeDeadline(deadline) {
                try await self.client.start()
            }
        case .disconnected:
            try await executeBeforeDeadline(deadline) {
                try await self.client.reconnect()
            }
        }
    }

    private func waitForClientConnectionToBecomeReady() async throws {
        for await state in makeConnectionStateStream() {
            switch state {
            case .connected:
                return
            case .idle:
                try await client.start()
                return
            case .disconnected:
                try await client.reconnect()
                return
            case .connecting, .reconnecting:
                continue
            }
        }
        
        throw CancellationError()
    }
    
    private func makeSubscription<Initial: Decodable & Sendable, Update: Decodable & Sendable>(
        method: SwiftFulcrum.RPC.Method,
        options: SwiftFulcrum.Client.Call.Options,
        deadline: TimeoutDeadline?
    ) async throws -> Subscription<Initial, Update> {
        if !method.isSubscription {
            throw SwiftFulcrum.Client.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use request(...) for unary calls.")
            )
        }

        try await prepareClientForRequests(until: deadline)
        
        let token = FulcrumNetworkClient.Call.Token()
        let callerCancellationToken = options.cancellation?.token
        let callerCancellationRegistrationID = await callerCancellationToken?.register {
            await token.cancel()
        }
        let effectiveOptions = try FulcrumNetworkClient.Call.Options(
            timeout: remainingTimeout(until: deadline),
            token: token
        )
        do {
            let (_, initial, updates): (UUID, Initial, AsyncThrowingStream<Update, Swift.Error>) =
            try await client.subscribe(method: method, options: effectiveOptions)
            if let callerCancellationToken, let callerCancellationRegistrationID {
                await callerCancellationToken.unregister(callerCancellationRegistrationID)
            }
            return Subscription(
                initial: initial,
                updates: updates,
                cancellationHandler: { await token.cancel() }
            )
        } catch {
            if let callerCancellationToken, let callerCancellationRegistrationID {
                await callerCancellationToken.unregister(callerCancellationRegistrationID)
            }
            throw adaptClientFacingError(error, originalLimit: deadline?.limit)
        }
    }

    private func makeDeadline(for limit: Duration?) -> TimeoutDeadline? {
        guard let limit else { return nil }

        let clock = ContinuousClock()
        return (limit: limit, instant: clock.now.advanced(by: limit))
    }

    private func makeClientOptions(
        from options: SwiftFulcrum.Client.Call.Options,
        constrainedBy deadline: TimeoutDeadline?
    ) throws -> FulcrumNetworkClient.Call.Options {
        .init(timeout: try remainingTimeout(until: deadline), token: options.cancellation?.token)
    }

    private func remainingTimeout(until deadline: TimeoutDeadline?) throws -> Duration? {
        guard let deadline else { return nil }
        return try remainingTimeoutBefore(deadline)
    }

    private func remainingTimeoutBefore(_ deadline: TimeoutDeadline) throws -> Duration {
        let now = ContinuousClock().now
        let remaining = now.duration(to: deadline.instant)

        guard remaining > .zero else {
            throw SwiftFulcrum.Client.Error.client(.timeout(deadline.limit))
        }

        return remaining
    }

    private func executeBeforeDeadline<T: Sendable>(
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

    private func remapTimeoutErrorIfNeeded(
        _ error: SwiftFulcrum.Client.Error,
        originalLimit: Duration?
    ) -> SwiftFulcrum.Client.Error {
        guard let originalLimit else { return error }

        if case .client(.timeout) = error {
            return .client(.timeout(originalLimit))
        }

        return error
    }

    private func adaptClientFacingError(
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
    
    private func executeWithTimeout<T: Sendable>(
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
