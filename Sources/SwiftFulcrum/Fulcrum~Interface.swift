// Fulcrum~Interface.swift

import Foundation

extension Fulcrum {
    /// Regular Request
    public func submit<JSONRPCResult: Sendable>(
        method: Method,
        responseType: Response.JSONRPC.Generic<JSONRPCResult>.Type
    ) async throws -> (UUID, JSONRPCResult) {
        let localClient   = self.client
        let requestID     = UUID()
        let request       = method.createRequest(with: requestID)
        guard let payload = request.data else { throw Client.Error.encodingFailed }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await localClient.insertRegularHandler(for: requestID) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCResult>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                switch responseType {
                                case .regular(let regularResponse):
                                    continuation.resume(returning: (regularResponse.id, regularResponse.result))
                                    
                                case .empty(let uuid):
                                    continuation.resume(
                                        throwing: Error.resultNotFound(description: "The response was empty for request id: \(uuid)")
                                    )
                                case .subscription(let subscriptionResponse):
                                    continuation.resume(
                                        throwing: Error.resultTypeMismatch(description: "Expected a regular response but received a subscription response (\(subscriptionResponse.methodPath) for request id: \(requestID)")
                                    )
                                case .error(let error):
                                    continuation.resume(
                                        throwing: Error.serverError(code: error.error.code, message: error.error.message)
                                    )
                                }
                            } catch {
                                continuation.resume(
                                    throwing: Error.decoding(underlyingError: error)
                                )
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    try await localClient.send(data: payload)
                } catch {
                    await localClient.removeRegularResponseHandler(for: requestID)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Subscription Request
    public func submit<JSONRPCNotification: Decodable>(
        method: Method,
        notificationType: Response.JSONRPC.Generic<JSONRPCNotification>.Type
    ) async throws -> (UUID,
                       JSONRPCNotification,
                       AsyncThrowingStream<JSONRPCNotification, Swift.Error>) {
        let localClient     = self.client
        let requestID       = UUID()
        let request         = method.createRequest(with: requestID)
        guard let payload   = request.data else { throw Client.Error.encodingFailed }
        let subscriptionKey = await Client.SubscriptionKey(methodPath: request.method,
                                                           identifier: localClient.identifier(for: method))
        
        ///*
        let initialResponse: JSONRPCNotification = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await localClient.insertRegularHandler(for: requestID) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                switch responseType {
                                case .regular(let regular):
                                    continuation.resume(returning: regular.result)
                                default:
                                    continuation.resume(throwing: Error.resultTypeMismatch(description: "The initial response of this subscription request (\(subscriptionKey)) is not a regular response."))
                                }
                            } catch {
                                continuation.resume(throwing: Error.decoding(underlyingError: error))
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    do {
                        try await localClient.send(data: payload)
                    } catch {
                        await localClient.removeRegularResponseHandler(for: requestID)
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let notificationStream = AsyncThrowingStream<JSONRPCNotification, Swift.Error> { continuation in
            Task {
                do {
                    try await localClient.insertSubscriptionHandler(for: subscriptionKey) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                switch responseType {
                                case .subscription(let subscription):
                                    continuation.yield(subscription.result)
                                    
                                case .empty(let uuid):
                                    continuation.finish(throwing: Error.resultNotFound(description: "The response was empty for request id: \(uuid)"))
                                case .regular(let regular):
                                    continuation.yield(regular.result)
                                case .error(let error):
                                    continuation.finish(throwing: Error.serverError(code: error.error.code, message: error.error.message))
                                }
                            } catch {
                                continuation.finish(throwing: Error.decoding(underlyingError: error))
                            }
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    }
                } catch {
                    await localClient.removeRegularResponseHandler(for: requestID)
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                Task {
                    await localClient.removeSubscriptionResponseHandler(for: subscriptionKey)
                    // TODO: send "unsubscribe" RPC here
                }
            }
        }
        // */
        
        /*
        var initialResponseContinuation: CheckedContinuation<JSONRPCNotification, Swift.Error>?
        var notificationStreamContinuation: AsyncThrowingStream<JSONRPCNotification, Swift.Error>.Continuation?
        
        let initialResponse: JSONRPCNotification = try await withCheckedThrowingContinuation { continuation in
            initialResponseContinuation = continuation
        }
        let notificationStream: AsyncThrowingStream<JSONRPCNotification, Swift.Error> = .init { continuation in
            notificationStreamContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task {
                    await localClient.removeSubscriptionResponseHandler(for: subscriptionKey)
                    // TODO: send "unsubscribe" RPC here
                }
            }
        }
        
        try await localClient.insertRegularHandler(for: requestID) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                    let responseType = try response.getResponseType()
                    
                    switch responseType {
                    case .regular(let regular):
                        initialResponseContinuation?.resume(returning: regular.result)
                    default:
                        initialResponseContinuation?.resume(throwing: Error.resultTypeMismatch(description: "The initial response of this subscription request (\(subscriptionKey)) is not a regular response."))
                    }
                } catch {
                    initialResponseContinuation?.resume(throwing: Error.decoding(underlyingError: error))
                }
            case .failure(let error):
                initialResponseContinuation?.resume(throwing: error)
            }
        }
        
        try await localClient.insertSubscriptionHandler(for: subscriptionKey) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                    let responseType = try response.getResponseType()
                    
                    switch responseType {
                    case .subscription(let subscription):
                        notificationStreamContinuation?.yield(subscription.result)
                        
                    case .empty(let uuid):
                        notificationStreamContinuation?.finish(throwing: Error.resultNotFound(description: "The response was empty for request id: \(uuid)"))
                    case .regular(let regular):
                        notificationStreamContinuation?.yield(regular.result)
                    case .error(let error):
                        notificationStreamContinuation?.finish(throwing: Error.serverError(code: error.error.code, message: error.error.message))
                    }
                } catch {
                    notificationStreamContinuation?.finish(throwing: Error.decoding(underlyingError: error))
                }
            case .failure(let error):
                notificationStreamContinuation?.finish(throwing: error)
            }
        }
        
        do {
            try await localClient.send(data: payload)
        } catch {
            await localClient.removeRegularResponseHandler(for: requestID)
            await localClient.removeSubscriptionResponseHandler(for: subscriptionKey)
            throw error
        }
        // */
        
        return (requestID, initialResponse, notificationStream)
    }
}

extension Fulcrum {
    private func handleInitialResponse<JSONRPCNotification: Decodable>(_ result: Result<Data, Fulcrum.Error>,
                                                                       continuation: CheckedContinuation<JSONRPCNotification, Swift.Error>) {
        switch result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                let responseType = try response.getResponseType()
                
                switch responseType {
                case .regular(let regularResponse):
                    continuation.resume(returning: regularResponse.result)
                default:
                    continuation.resume(throwing: Fulcrum.Error.resultTypeMismatch(description: "The initial response was not a regular response."))
                }
            } catch {
                continuation.resume(throwing: Error.decoding(underlyingError: error))
            }
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
    
    private func handleNotification<JSONRPCNotification: Decodable>(_ result: Result<Data, Fulcrum.Error>,
                                                                    continuation: AsyncThrowingStream<JSONRPCNotification, Swift.Error>.Continuation) {
        switch result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                let responseType = try response.getResponseType()
                
                switch responseType {
                case .subscription(let subscriptionResponse):
                    continuation.yield(subscriptionResponse.result)
                case .regular(let regularResponse):
                    continuation.yield(regularResponse.result)
                case .empty(let uuid):
                    continuation.finish(throwing: Error.resultNotFound(description: "The notification of UUID \(uuid) was not found."))
                case .error(let error):
                    continuation.finish(throwing: Error.serverError(code: error.error.code, message: error.error.message))
                }
            } catch {
                continuation.finish(throwing: Error.decoding(underlyingError: error))
            }
        case .failure(let error):
            continuation.finish(throwing: error)
        }
    }
}
