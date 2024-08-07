import Foundation

extension Client {
    func send(data: Data) async throws {
        try await webSocket.send(data: data)
    }
    
    func send(string: String) async throws {
        try await webSocket.send(string: string)
    }
}

extension Client {
    func handleResponseData(_ data: Data) {
        do {
            try externalDataHandler?(data)
        } catch {
            print("Oops. \(error)")
        }
    }
}

extension Client {
    func setupWebSocketSubscriptions() {
        webSocket.receivedData
            .sink { [weak self] data in
                self?.handleResponseData(data)
            }
            .store(in: &subscriptions)
        
        webSocket.receivedString
            .sink { [weak self] string in
                do {
                    guard let data = string.data(using: .utf8) else { throw WebSocket.Error.message(message: .string(string), reason: .encoding, description: "While publishing received message, there is encoding error.")}
                    self?.handleResponseData(data)
                } catch {
                    print("Empty data is published because converting from string to data failed.")
                }
            }
            .store(in: &subscriptions)
    }
}
