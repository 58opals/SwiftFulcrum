// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    /// Issues a unary JSON-RPC request and waits for its decoded response.
    ///
    /// - Parameters:
    ///   - method: RPC method to invoke. Subscription methods are rejected.
    ///   - responseType: Expected result model for decoding.
    ///   - options: Optional timeout and cancellation controls. Cancelling the calling task cancels the request.
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self,
        options: Fulcrum.Call.Options = .init()
    ) async throws -> RPCResponse<RegularResponseResult, Never> {
        if method.isSubscription {
            throw Fulcrum.Error.client(.protocolMismatch("submit() cannot be used with subscription methods. Use subscribe(...)."))
        }
        
        try await ensureClientIsReadyForRequests(within: options.timeout)
        
        do {
            let (id, result): (UUID, RegularResponseResult) = try await client.call(method: method, options: options.clientOptions)
            return .single(id: id, result: result)
        } catch let fulcrumError as Fulcrum.Error {
            throw fulcrumError
        } catch {
            throw Fulcrum.Error.client(.unknown(error))
        }
    }
    
    /// Starts a subscription and returns the initial response plus an update stream.
    ///
    /// - Parameters:
    ///   - method: Subscription RPC method to invoke.
    ///   - initialType: Expected model for decoding the initial response.
    ///   - notificationType: Expected model for decoding subscription updates.
    ///   - options: Optional timeout and cancellation controls. Cancelling the calling task cancels the subscription setup.
    /// - Returns: The initial subscription payload, an update stream, and a cancellation closure tied to the subscription token.
    public func subscribe<Initial: JSONRPCConvertible, Notification: JSONRPCConvertible>(
        method: Method,
        initialType: Initial.Type = Initial.self,
        notificationType: Notification.Type = Notification.self,
        options: Fulcrum.Call.Options = .init()
    ) async throws -> (Initial, AsyncThrowingStream<Notification, Swift.Error>, @Sendable () async -> Void) {
        let subscription = try await makeSubscription(
            method: method,
            initialType: initialType,
            notificationType: notificationType,
            options: options
        )
        return (subscription.initialResponse, subscription.updates, subscription.cancel)
    }
}

// MARK: -
extension Fulcrum {
    private func ensureClientIsReadyForRequests(within timeout: Duration?) async throws {
        guard let timeout else {
            try await prepareClientForRequests()
            return
        }
        
        try await executeWithTimeout(limit: timeout) {
            try await self.prepareClientForRequests()
        }
    }
    
    private func prepareClientForRequests() async throws {
        if !isRunning {
            try await start()
        }
        
        let state = await client.connectionState
        
        switch state {
        case .connected:
            return
        case .connecting, .idle, .reconnecting:
            try await client.start()
        case .disconnected:
            try await client.reconnect()
        }
    }
    
    private func makeSubscription<Initial: JSONRPCConvertible, Notification: JSONRPCConvertible>(
        method: Method,
        initialType: Initial.Type,
        notificationType: Notification.Type,
        options: Fulcrum.Call.Options
    ) async throws -> (
        identifier: UUID,
        initialResponse: Initial,
        updates: AsyncThrowingStream<Notification, Swift.Error>,
        cancel: @Sendable () async -> Void
    ) {
        if !method.isSubscription {
            throw Fulcrum.Error.client(
                .protocolMismatch("subscribe() requires subscription methods. Use submit(...) for unary calls.")
            )
        }
        
        try await ensureClientIsReadyForRequests(within: options.timeout)
        
        let token = options.cancellation?.token ?? Client.Call.Token()
        let effectiveOptions = Client.Call.Options(timeout: options.timeout, token: token)
        do {
            let (identifier, initial, updates): (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>) =
            try await client.subscribe(method: method, options: effectiveOptions)
            return (
                identifier,
                initial,
                updates,
                { await token.cancel() }
            )
        } catch let fulcrumError as Fulcrum.Error {
            throw fulcrumError
        } catch {
            throw Fulcrum.Error.client(.unknown(error))
        }
    }
    
    private func executeWithTimeout<T: Sendable>(
        limit: Duration,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            
            group.addTask {
                try await Task.sleep(for: limit)
                throw Fulcrum.Error.client(.timeout(limit))
            }
            
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            
            group.cancelAll()
            return result
        }
    }
}
