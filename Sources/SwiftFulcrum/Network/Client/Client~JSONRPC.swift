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

extension Client: ClientEventHandlable {
    func handleResponseData(_ data: Data) {
        do {
            try self.jsonRPC.storeResponse(from: data)
        } catch {
            print("While storing data(\(String(data: data, encoding: .utf8)!), we have a JSONRPC error: \(error)")
        }
    }
}
