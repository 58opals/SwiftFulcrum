// WebSocketConnectionValidator~Support.swift

import Foundation
import Network
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
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
            try await task.value
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

    static let diagnosticsConfiguration = OpalDiagnostics.Configuration(
        minimumLevel: .debug,
        categoryFilter: .enabledIncludingSubcategories([OpalDiagnostics.Category.fulcrum]),
        bufferPolicy: .enabled(capacity: 1_000)
    )

    func findField(_ name: String, in record: OpalDiagnostics.Record) -> OpalDiagnostics.Field? {
        record.fields.first { $0.name == name }
    }
}
