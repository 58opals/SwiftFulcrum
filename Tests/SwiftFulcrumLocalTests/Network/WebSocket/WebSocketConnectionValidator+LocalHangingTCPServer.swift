// WebSocketConnectionValidator+LocalHangingTCPServer.swift

import Foundation
import Network

extension WebSocketConnectionValidator {
    actor LocalHangingTCPServer {
        private let listener: NWListener
        private let queue = DispatchQueue(label: "SwiftFulcrumLocalHangingTCPServer")
        private var connections: [NWConnection] = .init()
        private var startContinuation: CheckedContinuation<URL, Swift.Error>?

        init() throws {
            listener = try NWListener(using: .tcp, on: .any)
        }

        func start() async throws -> URL {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<URL, Swift.Error>) in
                startContinuation = continuation

                listener.stateUpdateHandler = { [server = self] state in
                    Task {
                        await server.handleStateUpdate(state)
                    }
                }

                listener.newConnectionHandler = { [server = self] connection in
                    Task {
                        await server.accept(connection)
                    }
                }

                listener.start(queue: queue)
            }
        }

        func stop() {
            let activeConnections = connections
            connections.removeAll(keepingCapacity: false)
            let continuation = startContinuation
            startContinuation = nil

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
            connections.append(connection)
            connection.start(queue: queue)
        }

        private func resolveStart(with result: Result<URL, Swift.Error>) {
            let continuation = startContinuation
            startContinuation = nil

            guard let continuation else { return }
            continuation.resume(with: result)
        }
    }
}
