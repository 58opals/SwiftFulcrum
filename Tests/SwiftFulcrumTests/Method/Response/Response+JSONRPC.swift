import Foundation
import Testing
@testable import SwiftFulcrum

struct ResponseJSONRPCTests {
    @Test("classifies live get_tip response as regular", .timeLimit(.minutes(1)))
    func classifyRegularResponse() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            let identifier = UUID()
            let method = Method.blockchain(.headers(.getTip))
            let request = method.createRequest(with: identifier)
            guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
            
            try await webSocket.send(data: payload)
            
            var capturedData: Data?
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
                    capturedData = data
                    break
                }
            }
            
            guard let body = capturedData else {
                await webSocket.disconnect()
                throw Fulcrum.Error.client(.protocolMismatch(method.path))
            }
            
            let rpcResponse = try JSONRPC.Coder.decoder.decode(
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.GetTip>.self,
                from: body
            )
            let kind = try rpcResponse.determineResponseType()
            
            switch kind {
            case .regular(let regular):
                #expect(regular.id == identifier)
                #expect(regular.result.height > 0)
                #expect(regular.result.hex.count == 64)
            default:
                Issue.record("Expected regular response, received: \(kind)")
            }
            
            await webSocket.disconnect()
        } catch {
            await webSocket.disconnect()
            throw error
        }
    }
    
    @Test("treats null height as empty response when expecting nonoptional", .timeLimit(.minutes(1)))
    func classifyEmptyResponse() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            let identifier = UUID()
            let method = Method.blockchain(.transaction(.getHeight(transactionHash: String(repeating: "0", count: 64))))
            let request = method.createRequest(with: identifier)
            guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
            
            try await webSocket.send(data: payload)
            
            var capturedData: Data?
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
                    capturedData = data
                    break
                }
            }
            
            guard let body = capturedData else {
                await webSocket.disconnect()
                throw Fulcrum.Error.client(.protocolMismatch(method.path))
            }
            
            let strictResponse = try JSONRPC.Coder.decoder.decode(
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetHeight>.self,
                from: body
            )
            let strictKind = try strictResponse.determineResponseType()
            
            switch strictKind {
            case .empty(let emptyIdentifier):
                #expect(emptyIdentifier == identifier)
            default:
                Issue.record("Expected empty kind, received: \(strictKind)")
            }
            
            let optionalResponse = try JSONRPC.Coder.decoder.decode(
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetHeight?>.self,
                from: body
            )
            let optionalKind = try optionalResponse.determineResponseType()
            
            switch optionalKind {
            case .regular(let regular):
                #expect(regular.id == identifier)
                #expect(regular.result == nil)
            default:
                Issue.record("Expected optional result to be treated as regular, received: \(optionalKind)")
            }
            
            await webSocket.disconnect()
        } catch {
            await webSocket.disconnect()
            throw error
        }
    }
    
    @Test("propagates rpc errors from invalid broadcast", .timeLimit(.minutes(1)))
    func classifyErrorResponse() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            let identifier = UUID()
            let method = Method.blockchain(.transaction(.broadcast(rawTransaction: "00")))
            let request = method.createRequest(with: identifier)
            guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
            
            try await webSocket.send(data: payload)
            
            var capturedData: Data?
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
                    capturedData = data
                    break
                }
            }
            
            guard let body = capturedData else {
                await webSocket.disconnect()
                throw Fulcrum.Error.client(.protocolMismatch(method.path))
            }
            
            let rpcResponse = try JSONRPC.Coder.decoder.decode(
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Broadcast>.self,
                from: body
            )
            let kind = try rpcResponse.determineResponseType()
            
            switch kind {
            case .error(let error):
                #expect(error.id == identifier)
                #expect(!error.error.message.isEmpty)
            default:
                Issue.record("Expected error response, received: \(kind)")
            }
            
            await webSocket.disconnect()
        } catch {
            await webSocket.disconnect()
            throw error
        }
    }
    
    @Test("detects subscription notifications from live headers stream", .timeLimit(.minutes(1)))
    func classifySubscriptionNotification() async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            let identifier = UUID()
            let method = Method.blockchain(.headers(.subscribe))
            let request = method.createRequest(with: identifier)
            guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
            
            try await webSocket.send(data: payload)
            
            var hasReceivedInitialResponse = false
            var subscriptionData: Data?
            let start = ContinuousClock.now
            
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
                switch responseIdentifier {
                case .uuid(let uuid) where uuid == identifier:
                    hasReceivedInitialResponse = true
                case .string(let path) where path == method.path:
                    subscriptionData = data
                    break
                default:
                    break
                }
                
                if ContinuousClock.now - start > .seconds(45) {
                    break
                }
            }
            
            guard hasReceivedInitialResponse else {
                await webSocket.disconnect()
                throw Fulcrum.Error.client(.protocolMismatch(method.path))
            }
            
            guard let body = subscriptionData else {
                await webSocket.disconnect()
                throw Fulcrum.Error.client(.protocolMismatch(method.path))
            }
            
            let rpcResponse = try JSONRPC.Coder.decoder.decode(
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self,
                from: body
            )
            let kind = try rpcResponse.determineResponseType()
            
            switch kind {
            case .subscription(let subscription):
                #expect(subscription.methodPath == method.path)
                switch subscription.result {
                case .topHeader(let header):
                    #expect(header.hex.count == 64)
                    #expect(header.height > 0)
                case .newHeader(let headers):
                    #expect(!headers.isEmpty)
                    for header in headers {
                        #expect(header.hex.count == 64)
                        #expect(header.height > 0)
                    }
                }
            default:
                Issue.record("Expected subscription notification, received: \(kind)")
            }
            
            await webSocket.disconnect()
        } catch {
            await webSocket.disconnect()
            throw error
        }
    }
}
