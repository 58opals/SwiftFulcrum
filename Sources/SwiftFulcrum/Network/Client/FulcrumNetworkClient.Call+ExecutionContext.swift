// FulcrumNetworkClient.Call+ExecutionContext.swift

import Foundation

extension FulcrumNetworkClient.Call {
    struct ExecutionContext<Success: Sendable>: Sendable {
        private let task: Task<Success, Swift.Error>
        private let token: Token?
        private let timeout: Duration?
        private let timeoutState: TimeoutState
        private let cancellationAction: @Sendable (SwiftFulcrum.Client.Error) async -> Void

        init(
            task: Task<Success, Swift.Error>,
            token: Token?,
            timeout: Duration?,
            timeoutState: TimeoutState,
            cancellationAction: @escaping @Sendable (SwiftFulcrum.Client.Error) async -> Void
        ) {
            self.task = task
            self.token = token
            self.timeout = timeout
            self.timeoutState = timeoutState
            self.cancellationAction = cancellationAction
        }

        func value() async throws -> Success {
            let cancellationRegistrationID = await token?.register {
                task.cancel()
                await cancellationAction(timeoutState.cancellationError)
            }

            if token != nil, cancellationRegistrationID == nil {
                task.cancel()
                throw await timeoutState.cancellationError
            }

            do {
                let value = try await withTaskCancellationHandler {
                    try await awaitValue()
                } onCancel: {
                    task.cancel()
                    Task {
                        await cancellationAction(timeoutState.cancellationError)
                    }
                }
                if let token, let cancellationRegistrationID {
                    await token.unregister(cancellationRegistrationID)
                }
                return value
            } catch {
                if let token, let cancellationRegistrationID {
                    await token.unregister(cancellationRegistrationID)
                }
                throw await remapCancellationError(error)
            }
        }

        private func awaitValue() async throws -> Success {
            guard let timeout else {
                return try await task.value
            }

            return try await awaitValue(before: timeout)
        }

        private func awaitValue(before timeout: Duration) async throws -> Success {
            let timeoutError = SwiftFulcrum.Client.Error.client(.timeout(timeout))

            return try await withThrowingTaskGroup(of: Success.self) { group in
                group.addTask {
                    try await task.value
                }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    await timeoutState.mark(timeoutError)
                    task.cancel()
                    await cancellationAction(timeoutError)
                    throw timeoutError
                }

                let value = try await group.next()!
                group.cancelAll()
                return value
            }
        }

        private func remapCancellationError(_ error: Swift.Error) async -> Swift.Error {
            guard let timeoutError = await timeoutState.timeoutError else {
                return error
            }

            if error is CancellationError {
                return timeoutError
            }

            if let clientError = error as? SwiftFulcrum.Client.Error,
               clientError == .client(.cancelled) {
                return timeoutError
            }

            return error
        }
    }
}
