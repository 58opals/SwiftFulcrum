// WebSocketConnectionValidator~Support.swift

import Foundation
import Network
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    func waitUntil(
        timeout: Duration,
        pollingInterval: Duration = .milliseconds(10),
        _ condition: @Sendable @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: pollingInterval)
        }

        return await condition()
    }

    func waitForCurrentTaskIdentifier(
        on webSocket: WebSocketConnection,
        timeout: Duration = .seconds(1)
    ) async throws -> Int {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if let taskIdentifier = await webSocket.task?.taskIdentifier {
                return taskIdentifier
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        throw TimeoutError.missingSocketTask
    }

    func assertCancelledConnect(_ task: Task<Void, Swift.Error>) async {
        do {
            try await awaitConnectTask(task, timeout: .milliseconds(250))
            Issue.record("Expected connect() task to terminate after explicit disconnect")
        } catch is CancellationError {
            return
        } catch let error as SwiftFulcrum.Client.Error {
            if case .transport(.connectionClosed(let code, let reason)) = error {
                #expect(code == .goingAway)
                #expect(reason == "test teardown")
                return
            }
            Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    func expectCancelledConnectWaiter(_ task: Task<Void, Swift.Error>) async {
        await #expect(throws: CancellationError.self) {
            try await awaitConnectTask(task, timeout: .milliseconds(250))
        }
    }

    func awaitConnectTask(
        _ task: Task<Void, Swift.Error>,
        timeout: Duration
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await task.awaitCancellableValue(cancelUnderlyingTask: false)
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw TimeoutError.missingSocketTask
            }

            try await group.next()
            group.cancelAll()
        }
    }

    static let diagnosticsConfiguration = OpalDiagnostics.Configuration(
        minimumLevel: .debug,
        categoryFilter: .enabledIncludingSubcategories([OpalDiagnostics.Category.fulcrum]),
        bufferPolicy: .enabled(capacity: 1_000)
    )

    func findField(_ name: String, in record: OpalDiagnostics.Record) -> OpalDiagnostics.Field? {
        record.fields.first { $0.name == name }
    }
}
