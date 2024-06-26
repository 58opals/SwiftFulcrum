import Foundation

extension Storage {
    class RequestBox {
        var requests: Set<Request> = []
        
        func store(request: Request) throws {
            requests.insert(request)
        }
        
        func getRequest(for id: UUID) throws -> Request {
            guard let request = requests.filter({ $0.id == id }).first else { throw Error.requestExistence(issue: .notFound, id: id) }
            return request
        }
    }
}
