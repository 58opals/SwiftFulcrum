import Foundation
import Combine

extension SwiftFulcrum {
    public func submit<JSONRPCResult: Decodable>(
        method: Method,
        responseType: Response.JSONRPC.Generic<JSONRPCResult>.Type
    ) async throws -> (UUID, Future<JSONRPCResult, Swift.Error>) {
        let localClient = self.client
        let requestedID = try await localClient.sendRequest(from: method)
        
        let resultPublisher = Future<JSONRPCResult, Swift.Error> { promise in
            Task {
                localClient.externalDataHandler = { receivedData in
                    do {
                        let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCResult>.self, from: receivedData).getResponseType()
                        switch response {
                        case .empty(let uuid):
                            _ = uuid
                            promise(.failure(Error.resultNotFound(description: "The response was empty for request ID: \(uuid).")))
                        case .regular(let regular):
                            promise(.success(regular.result))
                        case .subscription(let subscription):
                            _ = subscription
                            promise(.failure(Error.resultTypeMismatch(description: "Expected a regular response but received a subscription response for request ID: \(requestedID).")))
                        case .error(let error):
                            promise(.failure(Error.serverError(code: error.error.code, message: error.error.message)))
                        }
                    } catch {
                        promise(.failure(Error.decoding(underlyingError: error)))
                    }
                }
            }
        }
        
        return (requestedID, resultPublisher)
    }
    
    public mutating func submit<JSONRPCResult: Decodable, JSONRPCNotification: Decodable>(
        method: Method,
        responseType: Response.JSONRPC.Generic<JSONRPCResult>.Type,
        notificationType: Response.JSONRPC.Generic<JSONRPCNotification>.Type
    ) async throws -> (UUID, PassthroughSubject<JSONRPCNotification, Swift.Error>) {
        let localClient = self.client
        let requestedID = try await localClient.sendRequest(from: method)
        
        let notificationPublisher: PassthroughSubject<JSONRPCNotification, Swift.Error> = .init()
        let resultPublisher: Future<JSONRPCResult, Swift.Error> = .init { promise in
            Task {
                localClient.externalDataHandler = { receivedData in
                    do {
                        let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCResult>.self, from: receivedData).getResponseType()
                        switch response {
                        case .empty(let uuid):
                            _ = uuid
                            promise(.failure(Error.resultNotFound(description: "The response was empty for request ID: \(uuid).")))
                        case .regular(let regular):
                            promise(.success(regular.result))
                        case .subscription(let subscription):
                            _ = subscription
                            promise(.failure(Error.resultTypeMismatch(description: "Expected a regular response but received a subscription response for request ID: \(requestedID).")))
                        case .error(let error):
                            promise(.failure(Error.serverError(code: error.error.code, message: "\(error.id): \(error.error.message)")))
                        }
                    } catch {
                        promise(.failure(Error.decoding(underlyingError: error)))
                    }
                }
            }
        }
        
        let subscription = resultPublisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        notificationPublisher.send(completion: .failure(error))
                    }
                },
                receiveValue: { initialResponse in
                    localClient.externalDataHandler = { receivedData in
                        do {
                            let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: receivedData).getResponseType()
                            switch response {
                            case .empty:
                                notificationPublisher.send(completion: .failure(Error.resultNotFound(description: "Received an empty response during notification handling.")))
                            case .regular:
                                notificationPublisher.send(completion: .failure(Error.resultTypeMismatch(description: "Expected a subscription response but received a regular response.")))
                            case .subscription(let subscription):
                                notificationPublisher.send(subscription.result)
                            case .error(let error):
                                notificationPublisher.send(completion: .failure(Error.serverError(code: error.error.code, message: error.error.message)))
                            }
                        } catch {
                            notificationPublisher.send(completion: .failure(Error.decoding(underlyingError: error)))
                        }
                    }
                })
        
        subscriptionHub.add(subscription, for: requestedID)
        
        return (requestedID, notificationPublisher)
    }
}
