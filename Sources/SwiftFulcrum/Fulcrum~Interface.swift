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
        guard let payload = request.data else { throw Error.coding(.encode(nil)) }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await localClient.insertRegularHandler(for: requestID) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let response = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.Generic<JSONRPCResult>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                switch responseType {
                                case .regular(let regularResponse):
                                    continuation.resume(returning: (regularResponse.id, regularResponse.result))
                                    
                                case .empty(let uuid):
                                    continuation.resume(throwing: Error.client(.emptyResponse(uuid)))
                                case .subscription(let subscriptionResponse):
                                    continuation.resume(throwing: Error.client(.protocolMismatch("[\(requestID)]: \(subscriptionResponse.methodPath)")))
                                case .error(let error):
                                    continuation.resume(throwing: Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message)))
                                }
                            } catch {
                                continuation.resume(
                                    throwing: Error.coding(.decode(error)))
                            }
                        case .failure(let failure):
                            continuation.resume(throwing: Error.client(.unknown(failure)))
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
    public func submit<JSONRPCNotification: Decodable & Sendable>(
        method: Method,
        notificationType: Response.JSONRPC.Generic<JSONRPCNotification>.Type
    ) async throws -> (UUID,
                       JSONRPCNotification,
                       AsyncThrowingStream<JSONRPCNotification, Swift.Error>) {
        let localClient     = self.client
        let requestID       = UUID()
        let request         = method.createRequest(with: requestID)
        guard let payload   = request.data else { throw Error.coding(.encode(nil)) }
        let subscriptionKey = await Client.SubscriptionKey(methodPath: request.method,
                                                           identifier: localClient.getSubscriptionIdentifier(for: method))
        
        let initialResponse: JSONRPCNotification = try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await localClient.insertRegularHandler(for: requestID) { result in
                        switch result {
                        case .success(let data):
                            do {
                                let response = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                
                                
                                switch responseType {
                                case .regular(let regularResponse):
                                    continuation.resume(returning: regularResponse.result)
                                    
                                case .empty(let uuid):
                                    continuation.resume(throwing: Error.client(.emptyResponse(uuid)))
                                case .subscription(let subscriptionResponse):
                                    continuation.resume(throwing: Error.client(.protocolMismatch("[\(requestID)]: \(subscriptionResponse.methodPath)")))
                                case .error(let error):
                                    continuation.resume(throwing: Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message)))
                                }
                            } catch {
                                continuation.resume(throwing: Error.coding(.decode(error)))
                            }
                        case .failure(let failure):
                            continuation.resume(throwing: Error.client(.unknown(failure)))
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
                                let response = try JSONRPC.Coder.decoder.decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: data)
                                let responseType = try response.getResponseType()
                                
                                switch responseType {
                                case .subscription(let subscriptionResponse):
                                    continuation.yield(subscriptionResponse.result)
                                
                                case .empty(let uuid):
                                    continuation.finish(throwing: Error.client(.emptyResponse(uuid)))
                                case .regular(let regularResponse):
                                    continuation.finish(throwing: Error.client(.protocolMismatch("[\(regularResponse.id)]")))
                                case .error(let error):
                                    continuation.finish(throwing: Error.rpc(.init(id: error.id, code: error.error.code, message: error.error.message)))
                                }
                            } catch {
                                continuation.finish(throwing: Error.coding(.decode(error)))
                            }
                        case .failure(let failure):
                            continuation.finish(throwing: Error.client(.unknown(failure)))
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
        
        return (requestID, initialResponse, notificationStream)
    }
}
