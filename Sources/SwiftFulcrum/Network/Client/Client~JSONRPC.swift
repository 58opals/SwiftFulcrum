import Foundation

extension Client {
    func sendRequest(from method: Method) async throws -> UUID {
        let request = method.request
        
        try await self.sendRequest(request)
        
        return request.id
    }
    
    func sendRequest(_ request: Request) async throws {
        try await self.send(data: request.data)
    }
}
