import Foundation
import Testing
@testable import SwiftFulcrum

struct ResponseDecodeTests {
    @Test("decodes regular responses for blockchain.headers.get_tip", .timeLimit(.minutes(1)))
    func decodeRegularResponses() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let method = Method.blockchain(.headers(.getTip))
            let (_, responseData) = try await send(method, via: webSocket, iterator: &iterator)
            
            let jsonResult = try responseData.decode(Response.JSONRPC.Result.Blockchain.Headers.GetTip.self)
            #expect(jsonResult.height > 0)
            #expect(jsonResult.hex.count == 64)
            
            let converted = try responseData.decode(
                Response.Result.Blockchain.Headers.GetTip.self,
                context: .init(methodPath: method.path)
            )
            #expect(converted.height == jsonResult.height)
            #expect(converted.hex == jsonResult.hex)
        }
    }
    
    @Test("propagates rpc errors when decoding invalid broadcast response", .timeLimit(.minutes(1)))
    func decodeErrorResponse() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let method = Method.blockchain(.transaction(.broadcast(rawTransaction: "00")))
            let (requestIdentifier, responseData) = try await send(method, via: webSocket, iterator: &iterator)
            
            do {
                _ = try responseData.decode(
                    Response.Result.Blockchain.Transaction.Broadcast.self,
                    context: .init(methodPath: method.path)
                )
                Issue.record("Expected rpc error while decoding invalid broadcast response")
            } catch let error as Fulcrum.Error {
                switch error {
                case .rpc(let serverError):
                    #expect(serverError.id == requestIdentifier)
                    #expect(!serverError.message.isEmpty)
                default:
                    Issue.record("Unexpected error: \(error)")
                }
            }
        }
    }
    
    @Test("fails with empty response when transaction height is missing", .timeLimit(.minutes(1)))
    func decodeEmptyResponse() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let method = Method.blockchain(.transaction(.getHeight(transactionHash: String(repeating: "0", count: 64))))
            let (requestIdentifier, responseData) = try await send(method, via: webSocket, iterator: &iterator)
            
            do {
                _ = try responseData.decode(
                    Response.Result.Blockchain.Transaction.GetHeight.self,
                    context: .init(methodPath: method.path)
                )
                Issue.record("Expected empty response error for unknown transaction height")
            } catch let error as Fulcrum.Error {
                switch error {
                case .client(.emptyResponse(let identifier)):
                    #expect(identifier == requestIdentifier)
                default:
                    Issue.record("Unexpected error: \(error)")
                }
            }
        }
    }
    
    @Test("annotates unexpected format errors with method context", .timeLimit(.minutes(1)))
    func decodeUnexpectedFormat() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let method = Method.blockchain(.address(.subscribe(address: "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a")))
            let (_, responseData) = try await send(method, via: webSocket, iterator: &iterator)
            
            do {
                _ = try responseData.decode(
                    Response.Result.Blockchain.Address.SubscribeNotification.self,
                    context: .init(methodPath: method.path)
                )
                Issue.record("Expected unexpected format error when decoding subscribe notification from initial response")
            } catch let formatError as Response.Result.Error {
                switch formatError {
                case .unexpectedFormat(let message):
                    #expect(message.contains("[method: \(method.path)]"))
                    #expect(message.contains("[payload: "))
                default:
                    Issue.record("Unexpected format error: \(formatError)")
                }
            }
        }
    }
    
    @Test("decodes async streams from captured live responses", .timeLimit(.minutes(1)))
    func decodeStreams() async throws {
        let method = Method.blockchain(.headers(.getTip))
        var captured = [Data]()
        
        try await withConnectedWebSocket { webSocket, iterator in
            for _ in 0..<2 {
                let (_, data) = try await send(method, via: webSocket, iterator: &iterator)
                captured.append(data)
            }
        }
        
        #expect(captured.count == 2)
        
        let capturedChunks = captured
        
        let firstRawStream = AsyncThrowingStream<Data, Swift.Error> { continuation in
            for chunk in capturedChunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
        
        var jsonValues = [Response.JSONRPC.Result.Blockchain.Headers.GetTip]()
        for try await value in firstRawStream.decode(Response.JSONRPC.Result.Blockchain.Headers.GetTip.self) {
            jsonValues.append(value)
        }
        #expect(jsonValues.count == captured.count)
        #expect(jsonValues.allSatisfy { $0.hex.count == 64 })
        
        let secondRawStream = AsyncThrowingStream<Data, Swift.Error> { continuation in
            for chunk in capturedChunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
        
        var convertedValues = [Response.Result.Blockchain.Headers.GetTip]()
        for try await value in secondRawStream.decode(
            Response.Result.Blockchain.Headers.GetTip.self,
            context: .init(methodPath: method.path)
        ) {
            convertedValues.append(value)
        }
        #expect(convertedValues.count == captured.count)
        for (json, converted) in zip(jsonValues, convertedValues) {
            #expect(json.height == converted.height)
            #expect(json.hex == converted.hex)
        }
    }
    
    private func send(
        _ method: SwiftFulcrum.Method,
        via webSocket: WebSocket,
        iterator: inout AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Iterator
    ) async throws -> (UUID, Data) {
        let identifier = UUID()
        let request = method.createRequest(with: identifier)
        guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
        
        try await webSocket.send(data: payload)
        
        while let message = try await iterator.next() {
            let data: Data
            switch message {
            case .data(let chunk):
                data = chunk
            case .string(let text):
                guard let converted = text.data(using: .utf8) else { continue }
                data = converted
            @unknown default:
                continue
            }
            
            let responseIdentifier = try Response.JSONRPC.extractIdentifier(from: data)
            if case .uuid(let uuid) = responseIdentifier, uuid == identifier {
                return (identifier, data)
            }
        }
        
        throw Fulcrum.Error.client(.protocolMismatch(method.path))
    }
    
    private func withConnectedWebSocket(
        _ operation: (WebSocket, inout AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Iterator) async throws -> Void
    ) async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            try await operation(webSocket, &iterator)
        } catch {
            await webSocket.disconnect()
            throw error
        }
        
        await webSocket.disconnect()
    }
}
