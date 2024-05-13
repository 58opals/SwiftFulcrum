import Foundation
import Combine

protocol SwiftFulcrumPublicCommunicatable {
    func sendRequest(_ method: Method) async throws -> UUID
    mutating func submitRequest<ResultType>(_ method: Method, resultType: ResultType.Type, behavior: @escaping (Swift.Result<ResultType, Swift.Error>) -> Void) async
    mutating func submitSubscription<NotificationType>(_ method: Method, notificationType: NotificationType.Type, behavior: @escaping (Swift.Result<NotificationType, Swift.Error>) -> Void) async
}
