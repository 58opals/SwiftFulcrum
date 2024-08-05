import Foundation
import Combine

extension SwiftFulcrum {
    func sendRequest(_ method: Method) async throws -> UUID {
        let uuid = try await client.sendRequest(from: method)
        return uuid
    }
    
    public mutating func submitRequest<ResultType>(_ method: Method, resultType: ResultType.Type, behavior: @escaping (Swift.Result<ResultType, Swift.Error>) -> Void) async {
        do {
            let requestedID = try await self.sendRequest(method)
            print(requestedID)
            
        } catch {
            behavior(.failure(error))
        }
    }
    
    public mutating func submitSubscription<NotificationType>(_ method: Method, notificationType: NotificationType.Type, behavior: @escaping (Swift.Result<NotificationType, Swift.Error>) -> Void) async {
        do {
            let requestedID = try await self.sendRequest(method)
            print(requestedID)
            
        } catch {
            behavior(.failure(error))
        }
    }
}
