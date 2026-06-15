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
