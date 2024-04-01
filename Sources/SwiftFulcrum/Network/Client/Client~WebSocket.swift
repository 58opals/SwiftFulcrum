import Foundation

extension Client: ClientWebSocketMessagable {
    func send(data: Data) async throws {
        try await webSocket.send(data: data)
    }
    
    func send(string: String) async throws {
        try await webSocket.send(string: string)
    }
}

extension Client: ClientWebSocketEventHandlable {
    func handleResponseData(_ data: Data) {
        do {
            try self.jsonRPC.storeResponse(from: data)
        } catch {
            print("While storing data(\(String(data: data, encoding: .utf8)!), we have a JSONRPC error: \(error)")
        }
    }
}

extension Client: ClientWebSocketEventSubscribable {
    func setupWebSocketSubscriptions() {
        webSocket.receivedData
            .sink { [weak self] data in
                self?.handleResponseData(data)
            }
            .store(in: &self.subscribers)
        
        webSocket.receivedString
            .sink { [weak self] string in
                do {
                    guard let data = string.data(using: .utf8) else { throw WebSocket.Error.message(message: .string(string), reason: .encoding, description: "While publishing received message, there is encoding error.")}
                    self?.handleResponseData(data)
                } catch {
                    print("Empty data is published because converting from string to data failed.")
                }
            }
            .store(in: &self.subscribers)
    }
}
