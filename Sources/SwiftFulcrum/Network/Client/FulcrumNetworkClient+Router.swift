// FulcrumNetworkClient+Router.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    actor Router {
        private var table: [SwiftFulcrum.RPC.Response.Identifier: PendingEntry] = .init()


        private var inflightUnaryCallCount = 0
        func makeInflightUnaryCallCount() -> Int { inflightUnaryCallCount }

        @discardableResult
        func addUnary(
            id: UUID,
            continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
            subscriptionRestore: SubscriptionRestoreContext? = nil
        ) throws -> Int {
            let key: SwiftFulcrum.RPC.Response.Identifier = .uuid(id)
            guard table[key] == nil else { throw SwiftFulcrum.Client.Error.client(.duplicateRegistration) }
            table[key] = .unary(continuation, subscriptionRestore: subscriptionRestore)
            inflightUnaryCallCount += 1
            return inflightUnaryCallCount
        }

        func addStream(
            key: String,
            continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
            registrationIdentifier: UUID,
            overflowError: Swift.Error?,
            terminationAction: @escaping @Sendable (Swift.Error?) async -> Void
        ) throws {
            try addStream(key: key, sink: .raw(continuation), registrationIdentifier: registrationIdentifier,
                overflowError: overflowError, terminationAction: terminationAction)
        }

        func addObservedStream(key: String, continuation: AsyncThrowingStream<SubscriptionResponse, Swift.Error>.Continuation,
            registrationIdentifier: UUID, overflowError: Swift.Error?,
            terminationAction: @escaping @Sendable (Swift.Error?) async -> Void) throws {
            try addStream(key: key, sink: .observed(continuation), registrationIdentifier: registrationIdentifier,
                overflowError: overflowError, terminationAction: terminationAction)
        }

        private func addStream(key: String, sink: SubscriptionSink, registrationIdentifier: UUID,
            overflowError: Swift.Error?, terminationAction: @escaping @Sendable (Swift.Error?) async -> Void) throws {
            let identifier: SwiftFulcrum.RPC.Response.Identifier = .string(key)
            guard table[identifier] == nil else { throw SwiftFulcrum.Client.Error.client(.duplicateRegistration) }
            table[identifier] = .stream(
                sink,
                registrationIdentifier: registrationIdentifier,
                overflowError: overflowError,
                terminationAction: terminationAction
            )
        }

        func handle(
            raw: Data,
            publicationGeneration: UInt64 = 0,
            generationAuthority: ConnectionRecoveryGeneration? = nil,
            isSubscriptionRestoreCurrent: (@Sendable (SubscriptionRestoreContext) async -> Bool)? = nil
        ) async -> Int? {
            let id: SwiftFulcrum.RPC.Response.Identifier
            do {
                id = try SwiftFulcrum.RPC.Response.JSONRPC.extractIdentifier(from: raw)
            } catch {
                if let remainingUnaryCallCount = handleUnidentifiedErrorResponse(raw) {
                    return remainingUnaryCallCount
                }
                recordUnroutableResponseDecodeFailure(raw: raw, error: error)
                return nil
            }

            switch id {
            case .uuid:
                if case .unary(_, let restore?) = table[id] {
                    let isCurrent = await isSubscriptionRestoreCurrent?(restore) ?? false
                    // The epoch check can suspend while cancellation replaces either route.
                    guard case .unary(_, let currentRestore?) = table[id], currentRestore == restore else {
                        return nil
                    }
                    let streamIdentifier = SwiftFulcrum.RPC.Response.Identifier.string(restore.subscriptionKey.string)
                    if isCurrent,
                       case .stream(_, let registrationIdentifier, _, _) = table[streamIdentifier],
                       registrationIdentifier == restore.streamRegistrationIdentifier {
                        do {
                            if let notification = try restore.makeNotification(from: raw) {
                                // Route the snapshot before releasing its acknowledgement so subsequent
                                // wire notifications cannot overtake it in the existing update stream.
                                restore.recoveryGenerationAuthority.publishIfCurrent(restore.recoveryGeneration) {
                                    _ = resolve(identifier: streamIdentifier, with: notification, generation: restore.recoveryGeneration)
                                }
                            }
                        } catch {
                            return cancel(identifier: id, error: error)
                        }
                    }
                }
                return resolve(identifier: id, with: raw)
            case .string(let methodPath):
                let suffix = FulcrumNetworkClient.makeSubscriptionIdentifier(methodPath: methodPath, data: raw)
                let key = suffix.map { "\(methodPath):\($0)" } ?? methodPath
                if let generationAuthority {
                    generationAuthority.publishIfCurrent(publicationGeneration) {
                        _ = resolve(identifier: .string(key), with: raw, generation: publicationGeneration)
                    }
                    return nil
                }
                return resolve(identifier: .string(key), with: raw, generation: publicationGeneration)
            }
        }

        @discardableResult
        func cancel(identifier: SwiftFulcrum.RPC.Response.Identifier, error: Swift.Error? = nil) -> Int? {
            guard let entry = table.removeValue(forKey: identifier) else { return nil }
            switch entry {
            case .unary(let continuation, _):
                continuation.finish(throwing: error ?? SwiftFulcrum.Client.Error.client(.cancelled))
                inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                return inflightUnaryCallCount
            case .stream(let continuation, _, _, _):
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
                case .unary(let continuation, _):
                    continuation.finish(throwing: error)
                case .stream(let continuation, _, _, _):
                    continuation.finish(throwing: error)
                }
            }

            return inflightUnaryCallCount
        }

        func failUnaries(with error: Swift.Error) -> Int {
            let current = table
            for (identifier, pending) in current {
                switch pending {
                case .unary(let checkedContinuation, _):
                    table.removeValue(forKey: identifier)
                    checkedContinuation.finish(throwing: error)
                    inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                case .stream:
                    continue
                }
            }

            return inflightUnaryCallCount
        }

        private func resolve(identifier: SwiftFulcrum.RPC.Response.Identifier, with raw: Data, generation: UInt64 = 0) -> Int? {
            guard let entry = table[identifier] else { return nil }
            switch entry {
            case .unary(let continuation, _):
                continuation.yield(raw)
                continuation.finish()
                table.removeValue(forKey: identifier)
                inflightUnaryCallCount = max(inflightUnaryCallCount - 1, 0)
                return inflightUnaryCallCount
            case .stream(let continuation, _, let overflowError, let terminationAction):
                switch continuation.yield(raw, generation: generation) {
                case .enqueued:
                    break
                case .dropped:
                    table.removeValue(forKey: identifier)
                    if let overflowError {
                        continuation.finish(throwing: overflowError)
                    } else {
                        continuation.finish()
                    }
                    Task {
                        await terminationAction(overflowError)
                    }
                case .terminated:
                    table.removeValue(forKey: identifier)
                    Task {
                        await terminationAction(nil)
                    }
                @unknown default:
                    table.removeValue(forKey: identifier)
                    if let overflowError {
                        continuation.finish(throwing: overflowError)
                    } else {
                        continuation.finish()
                    }
                    Task {
                        await terminationAction(overflowError)
                    }
                }
            }

            return nil
        }

        private func handleUnidentifiedErrorResponse(_ raw: Data) -> Int? {
            guard
                case .error(let error) = try? SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: raw)
            else { return nil }

            return failUnaries(with: error)
        }

        private func recordUnroutableResponseDecodeFailure(raw: Data, error: Swift.Error) {
            OpalDiagnostics.logger(category: .swiftFulcrumJSONRPC).record(
                event: .swiftFulcrumJSONRPCResponseDecodeFailed,
                level: .info,
                fields: [
                    .swiftFulcrumField("byte_count", raw.count)
                ] + OpalDiagnostics.Field.swiftFulcrumErrorFields(error)
            )
        }
    }
}
