// Client+Router.swift

import Foundation

extension Client {
    actor Router {
        private enum Pending {
            case unary(CheckedContinuation<Data, Swift.Error>)
            case stream(AsyncThrowingStream<Data, Swift.Error>.Continuation)
        }
        
        private var table: [Response.Identifier: Pending] = .init()
        
        func addUnary(id: UUID, continuation: CheckedContinuation<Data, Swift.Error>) throws {
            let key: Response.Identifier = .uuid(id)
            guard table[key] == nil else { throw Fulcrum.Error.client(.duplicateHandler) }
            table[key] = .unary(continuation)
        }
        
        func addStream(key: String, continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation) throws {
            let identifier: Response.Identifier = .string(key)
            guard table[identifier] == nil else { throw Fulcrum.Error.client(.duplicateHandler) }
            table[identifier] = .stream(continuation)
        }
        
        func handle(raw: Data) {
            guard let id = try? Response.JSONRPC.extractIdentifier(from: raw) else { return }
            switch id {
            case .uuid:
                resolve(identifier: id, with: raw)
            case .string(let methodPath):
                let suffix = Client.subscriptionIdentifier(methodPath: methodPath, data: raw)
                let key = suffix.map { "\(methodPath):\($0)" } ?? methodPath
                resolve(identifier: .string(key), with: raw)
            }
        }
        
        func cancel(identifier: Response.Identifier, error: Swift.Error? = nil) {
            guard let entry = table.removeValue(forKey: identifier) else { return }
            switch entry {
            case .unary(let continuation):
                continuation.resume(throwing: error ?? Fulcrum.Error.client(.cancelled))
            case .stream(let continuation):
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
        }
        
        func failAll(with error: Swift.Error) {
            let entries = table
            table.removeAll()
            
            for pending in entries.values {
                switch pending {
                case .unary(let continuation):
                    continuation.resume(throwing: error)
                case .stream(let continuation):
                    continuation.finish(throwing: error)
                }
            }
        }
        
        func failUnaries(with error: Swift.Error) {
            let current = table
            for (identifier, pending) in current {
                switch pending {
                case .unary(let checkedContinuation):
                    table.removeValue(forKey: identifier)
                    checkedContinuation.resume(throwing: error)
                case .stream:
                    continue
                }
            }
        }
        
        private func resolve(identifier: Response.Identifier, with raw: Data) {
            guard let entry = table[identifier] else { return }
            switch entry {
            case .unary(let continuation):
                continuation.resume(returning: raw)
                table.removeValue(forKey: identifier)
            case .stream(let continuation):
                continuation.yield(raw)
            }
        }
    }
}
