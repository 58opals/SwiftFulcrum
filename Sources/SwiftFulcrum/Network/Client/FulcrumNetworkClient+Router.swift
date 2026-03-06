// FulcrumNetworkClient+Router.swift

import Foundation

extension FulcrumNetworkClient {
    actor Router {
        private enum PendingModel {
            case unary(AsyncThrowingStream<Data, Swift.Error>.Continuation)
            case stream(AsyncThrowingStream<Data, Swift.Error>.Continuation)
        }
        
        private var table: [SwiftFulcrum.RPC.Response.Identifier: PendingModel] = .init()
        
        
        private var inflightUnaryCallCount = 0
        func makeInflightUnaryCallCount() -> Int { inflightUnaryCallCount }
        
        @discardableResult
        func addUnary(id: UUID, continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation) throws -> Int {
            let key: SwiftFulcrum.RPC.Response.Identifier = .uuid(id)
            guard table[key] == nil else { throw SwiftFulcrum.Client.Error.client(.duplicateHandler) }
            table[key] = .unary(continuation)
            inflightUnaryCallCount += 1
            return inflightUnaryCallCount
        }
        
        func addStream(key: String, continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation) throws {
            let identifier: SwiftFulcrum.RPC.Response.Identifier = .string(key)
            guard table[identifier] == nil else { throw SwiftFulcrum.Client.Error.client(.duplicateHandler) }
            table[identifier] = .stream(continuation)
        }
        
        func handle(raw: Data) -> Int? {
            guard let id = try? SwiftFulcrum.RPC.Response.JSONRPC.extractIdentifier(from: raw) else { return nil }
            switch id {
            case .uuid:
                return resolve(identifier: id, with: raw)
            case .string(let methodPath):
                let suffix = FulcrumNetworkClient.makeSubscriptionIdentifier(methodPath: methodPath, data: raw)
                let key = suffix.map { "\(methodPath):\($0)" } ?? methodPath
                return resolve(identifier: .string(key), with: raw)
            }
        }
        
        @discardableResult
        func cancel(identifier: SwiftFulcrum.RPC.Response.Identifier, error: Swift.Error? = nil) -> Int? {
            guard let entry = table.removeValue(forKey: identifier) else { return nil }
            switch entry {
            case .unary(let continuation):
                continuation.finish(throwing: error ?? SwiftFulcrum.Client.Error.client(.cancelled))
                inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                return inflightUnaryCallCount
            case .stream(let continuation):
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
            return nil
        }
        
        func failAll(with error: Swift.Error) -> Int {
            let entries = table
            table.removeAll()
            inflightUnaryCallCount = 0
            
            for pending in entries.values {
                switch pending {
                case .unary(let continuation):
                    continuation.finish(throwing: error)
                case .stream(let continuation):
                    continuation.finish(throwing: error)
                }
            }
            
            return inflightUnaryCallCount
        }
        
        func failUnaries(with error: Swift.Error) -> Int {
            let current = table
            for (identifier, pending) in current {
                switch pending {
                case .unary(let checkedContinuation):
                    table.removeValue(forKey: identifier)
                    checkedContinuation.finish(throwing: error)
                    inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                case .stream:
                    continue
                }
            }
            
            return inflightUnaryCallCount
        }
        
        private func resolve(identifier: SwiftFulcrum.RPC.Response.Identifier, with raw: Data) -> Int? {
            guard let entry = table[identifier] else { return nil }
            switch entry {
            case .unary(let continuation):
                continuation.yield(raw)
                continuation.finish()
                table.removeValue(forKey: identifier)
                inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                return inflightUnaryCallCount
            case .stream(let continuation):
                continuation.yield(raw)
            }
            
            return nil
        }
    }
}
