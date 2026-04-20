// WebSocketConnectionValidator+LocalHangingTCPServer.swift

import Foundation
import Network

extension WebSocketConnectionValidator {
    final class LocalHangingTCPServer: @unchecked Sendable {
        private let listener: NWListener
        private let queue = DispatchQueue(label: "SwiftFulcrumLocalHangingTCPServer")
        private let lock = NSLock()
        private var connections: [NWConnection] = .init()
        private var startContinuation: CheckedContinuation<URL, Swift.Error>?

        init() throws {
            listener = try NWListener(using: .tcp, on: .any)
        }

        func start() async throws -> URL {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<URL, Swift.Error>) in
                lock.lock()
                startContinuation = continuation
                lock.unlock()

                listener.stateUpdateHandler = { [weak self] state in
                    self?.handleStateUpdate(state)
                }

                listener.newConnectionHandler = { [weak self] connection in
                    self?.accept(connection)
                }

                listener.start(queue: queue)
            }
        }

        func stop() {
            lock.lock()
            let activeConnections = connections
            connections.removeAll(keepingCapacity: false)
            let continuation = startContinuation
            startContinuation = nil
            lock.unlock()

            for connection in activeConnections {
                connection.cancel()
            }
            continuation?.resume(throwing: CancellationError())
            listener.cancel()
        }

        private func handleStateUpdate(_ state: NWListener.State) {
            switch state {
            case .ready:
                guard let port = listener.port else { return }
                resolveStart(with: .success(URL(string: "ws://127.0.0.1:\(port.rawValue)")!))
            case .failed(let error):
                resolveStart(with: .failure(error))
            default:
                break
            }
        }

        private func accept(_ connection: NWConnection) {
            lock.lock()
            connections.append(connection)
            lock.unlock()
            connection.start(queue: queue)
        }

        private func resolveStart(with result: Result<URL, Swift.Error>) {
            lock.lock()
            let continuation = startContinuation
            startContinuation = nil
            lock.unlock()

            guard let continuation else { return }
            continuation.resume(with: result)
        }
    }
}
