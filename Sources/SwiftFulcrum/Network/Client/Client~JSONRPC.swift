import Foundation

extension Client: ClientJSONRPCMessagable {
    func sendRequest(from method: Method) async throws -> UUID {
        let request = method.request
        
        try await self.sendRequest(request)
        try self.jsonRPC.storage.request.store(request: request)
        
        return request.id
    }
    
    func sendRequest(_ request: Request) async throws {
        try await self.send(data: request.data)
    }
}
