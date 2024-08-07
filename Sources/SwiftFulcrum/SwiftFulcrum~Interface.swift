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
    
    public mutating func submit<JSONRPCNotification: Decodable>(
        method: Method,
        notificationType: Response.JSONRPC.Generic<JSONRPCNotification>.Type
    ) async throws -> (UUID, CurrentValueSubject<JSONRPCNotification?, Swift.Error>) {
        let localClient = self.client
        let requestedID = try await localClient.sendRequest(from: method)
        
        let notificationPublisher: CurrentValueSubject<JSONRPCNotification?, Swift.Error> = .init(nil)
        
        localClient.externalDataHandler = { receivedData in
            do {
                print("notification data received: \(String(data: receivedData, encoding: .utf8)!)")
                let response = try JSONDecoder().decode(Response.JSONRPC.Generic<JSONRPCNotification>.self, from: receivedData)
                let responseType = try response.getResponseType()
                
                switch responseType {
                case .empty:
                    notificationPublisher.send(completion: .failure(Error.resultNotFound(description: "Received an empty response during notification handling.")))
                case .regular(let regular):
                    notificationPublisher.send(regular.result)
                case .subscription(let subscription):
                    notificationPublisher.send(subscription.result)
                case .error(let error):
                    notificationPublisher.send(completion: .failure(Error.serverError(code: error.error.code, message: error.error.message)))
                }
            } catch {
                notificationPublisher.send(completion: .failure(Error.decoding(underlyingError: error)))
            }
        }
        
        return (requestedID, notificationPublisher)
    }
}
