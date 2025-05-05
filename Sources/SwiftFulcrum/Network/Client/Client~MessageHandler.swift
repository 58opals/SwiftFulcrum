// Client~MessageHandler.swift

import Foundation

extension Client {
    func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .data(let data):
            await router.handle(raw: data)
            await self.handleData(data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                await router.handle(raw: data)
                await self.handleData(data)
            }
            else { print("Failed to convert string message to Data.") }
        @unknown default:
            print("Unknown message type")
        }
    }
    
    private enum Inbound {
        private struct RPCErrorEnvelope: Decodable { let id: UUID?; let error: Response.Error.Result }
        static func serverError(from data: Data) -> Fulcrum.Error? {
            guard let envelope = try? JSONRPC.Coder.decoder.decode(RPCErrorEnvelope.self, from: data) else { return nil }
            return .rpc(.init(id: envelope.id, code: envelope.error.code, message: envelope.error.message))
        }
    }
    
    func handleData(_ data: Data) async {
        do {
            let identifier = try Response.JSONRPC.extractIdentifier(from: data)
            switch identifier {
            case .uuid(let identifier):
                if let handler = regularResponseHandlers[identifier] {
                    if let fail = Inbound.serverError(from: data) {
                        handler(.failure(fail))
                    } else {
                        handler(.success(data))
                    }
                    removeRegularResponseHandler(for: identifier)
                } else {
                    print("No handler for regular response identifier: \(identifier)")
                }
            case .string(let methodPath):
                let identifier = getIdentifierFromNotification(methodPath: methodPath, data: data)
                let key        = SubscriptionKey(methodPath: methodPath, identifier: identifier)
                
                if let handler = subscriptionResponseHandlers[key] {
                    if let fail = Inbound.serverError(from: data) {
                        handler(.failure(fail))
                        removeSubscriptionResponseHandler(for: key)
                    } else {
                        handler(.success(data))
                    }
                } else {
                    print("No subscription handler for \(key)")
                }
            }
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
}
