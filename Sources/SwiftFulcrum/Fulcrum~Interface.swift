// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    public func submit<RegularResponseResult: JSONRPCConvertible>(
        method: Method,
        responseType: RegularResponseResult.Type = RegularResponseResult.self,
        options: Client.Call.Options = .init()
    ) async throws -> RPCResponse<RegularResponseResult, Never> {
        if method.isSubscription {
            throw Fulcrum.Error.client(.protocolMismatch("submit() cannot be used with subscription methods. Use subscribe(...)."))
        }
        
        do {
            let (id, result): (UUID, RegularResponseResult) = try await client.call(method: method, options: options)
            return .single(id: id, result: result)
        } catch let fulcrumError as Fulcrum.Error {
            throw fulcrumError
        } catch {
            throw Fulcrum.Error.client(.unknown(error))
        }
    }
    
    public func submit<Initial: JSONRPCConvertible, Notification: JSONRPCConvertible>(
        method: Method,
        initialType: Initial.Type = Initial.self,
        notificationType: Notification.Type = Notification.self,
        options: Client.Call.Options = .init()
    ) async throws -> RPCResponse<Initial, Notification> {
        let token = options.token ?? Client.Call.Token()
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
