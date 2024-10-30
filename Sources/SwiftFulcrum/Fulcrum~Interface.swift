import Foundation

extension Fulcrum {
    public func submit<JSONRPCResult: Sendable>(
        method: Method,
        responseType: Response.JSONRPC.Generic<JSONRPCResult>.Type
    ) async throws -> (UUID, JSONRPCResult) {
        let localClient = self.client
        let identifier = try await localClient.sendRequest(from: method)
        let requestID = identifier.uuid
        
        let result: JSONRPCResult = try await withCheckedThrowingContinuation { continuation in
            Task {
                await localClient.removeRegularResponseHandler(for: requestID)
                await localClient.addHandler(for: requestID) { receivedData in
                    //print(String(data: receivedData, encoding: .utf8)!)
                    
                    do {
                        let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCResult>.self, from: receivedData)
                        let responseType = try response.getResponseType()
                        
                        switch responseType {
                        case .empty(let uuid):
                            guard requestID == uuid else {
                                continuation.resume(throwing: Error.resultNotFound(description: "Response id \(uuid) is not matched with request id \(requestID)."))
                                return
                            }
                            continuation.resume(throwing: Error.resultNotFound(description: "The response was empty for request id: \(uuid)"))
                            
                        case .regular(let regular):
                            continuation.resume(returning: regular.result)
                            
                        case .subscription(_):
                            continuation.resume(throwing: Error.resultTypeMismatch(description: "Expected a regular response but received a subscription response for request id: \(requestID)"))
                            
                        case .error(let jsonrpcError):
                            continuation.resume(throwing: Error.serverError(code: jsonrpcError.error.code, message: jsonrpcError.error.message))
                        }
                    } catch {
                        continuation.resume(throwing: Error.decoding(underlyingError: error))
                    }
                }
            }
        }
        
        return (requestID, result)
    }
    
    public func submit<JSONRPCNotification: Decodable>(
        method: Method,
        notificationType: Response.JSONRPC.Generic<JSONRPCNotification>.Type
    ) async throws -> (UUID, JSONRPCNotification?, AsyncStream<JSONRPCNotification?>) {
        let localClient = self.client
        let identifier = try await localClient.sendRequest(from: method)
        let requestID = identifier.uuid
        let requestMethod = identifier.string
        
        let result: JSONRPCNotification? = try await withCheckedThrowingContinuation { continuation in
            Task {
                await localClient.removeRegularResponseHandler(for: requestID)
                await localClient.addHandler(for: requestID) { receivedData in
                    //print(String(data: receivedData, encoding: .utf8)!)
                    
                    do {
                        let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: receivedData)
                        let responseType = try response.getResponseType()
                        
                        switch responseType {
                        case .empty(let uuid):
                            guard requestID == uuid else {
                                continuation.resume(throwing: Error.resultNotFound(description: "Response id \(uuid) is not matched with request id \(requestID)."))
                                return
                            }
                            continuation.resume(returning: nil)
                        case .regular(let regular):
                            continuation.resume(returning: regular.result)
                        case .subscription(_):
                            continuation.resume(throwing: Error.resultTypeMismatch(description: "Expected a regular response but received a subscription response for request id: \(requestID)"))
                        case .error(let jsonrpcError):
                            continuation.resume(throwing: Error.serverError(code: jsonrpcError.error.code, message: jsonrpcError.error.message))
                        }
                    } catch {
                        continuation.resume(throwing: Error.decoding(underlyingError: error))
                    }
                }
            }
        }
        
        let notificationStream = AsyncStream<JSONRPCNotification?> { continuation in
            Task {
                await localClient.addHandler(for: requestMethod) { receivedData in
                    //print(String(data: receivedData, encoding: .utf8)!)
                    
                    do {
                        let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: receivedData)
                        let responseType = try response.getResponseType()
                        
                        switch responseType {
                        case .empty(_):
                            continuation.yield(nil)
                            
                        case .regular(let regular):
                            continuation.yield(regular.result)
                            
                        case .subscription(let subscription):
                            continuation.yield(subscription.result)
                            
                        case .error(let jsonrpcError):
                            print("Error(\(jsonrpcError.id.uuidString): \(jsonrpcError.error.code) - \(jsonrpcError.error.message)")
                            continuation.finish()
                        }
                    } catch {
                        print("Decoding error: \(error.localizedDescription)")
                        continuation.finish()
                    }
                }
            }
        }
        
        return (requestID, result, notificationStream)
    }
}
