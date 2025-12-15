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
    /// The returned ``RPCResponse.stream`` includes a `cancel` closure wired to the provided
    /// cancellation token if supplied. Cancelling the caller halts the subscription setup;
    /// cancelling the returned stream or the provided token terminates the server subscription.
    public func submit<Initial: JSONRPCConvertible, Notification: JSONRPCConvertible>(
        method: Method,
        initialType: Initial.Type = Initial.self,
        notificationType: Notification.Type = Notification.self,
        options: Fulcrum.Call.Options = .init()
    ) async throws -> RPCResponse<Initial, Notification> {
        let token = options.cancellation?.token ?? Client.Call.Token()
        let effectiveOptions = Client.Call.Options(timeout: options.timeout, token: token)
        do {
            let (id, initial, updates): (UUID, Initial, AsyncThrowingStream<Notification, Swift.Error>) =
            try await client.subscribe(method: method, options: effectiveOptions)
            return .stream(
                id: id,
                initialResponse: initial,
                updates: updates,
                cancel: { await token.cancel() }
            )
        } catch let fulcrumError as Fulcrum.Error {
            throw fulcrumError
        } catch {
            throw Fulcrum.Error.client(.unknown(error))
        }
    }
}
