// ClientConfigurationValidator.swift

import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientConfigurationValidator {
    @Test("fixed-endpoint initialization rejects invalid connection timeouts", arguments: [
        -1,
        Double.nan,
        Double.infinity,
        -Double.infinity,
        SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds + 1,
        Double.greatestFiniteMagnitude
    ])
    func rejectInvalidConnectionTimeout(_ invalidValue: TimeInterval) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.connectionTimeout = invalidValue
        let invalidConfiguration = configuration
        let endpoint = try #require(URL(string: "ws://example.com"))

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: invalidConfiguration)
        }
    }

    @Test("initialization rejects invalid base reconnect delays", arguments: [
        -1,
        Double.nan,
        Double.infinity,
        -Double.infinity,
        SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds + 1,
        Double.greatestFiniteMagnitude
    ])
    func rejectInvalidReconnectionDelay(_ invalidValue: TimeInterval) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.reconnect.reconnectionDelay = invalidValue
        let invalidConfiguration = configuration
        let endpoint = try #require(URL(string: "ws://example.com"))

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: invalidConfiguration)
        }
    }

    @Test("initialization rejects invalid maximum reconnect delays", arguments: [
        -1,
        Double.nan,
        Double.infinity,
        -Double.infinity,
        SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds + 1,
        Double.greatestFiniteMagnitude
    ])
    func rejectInvalidMaximumDelay(_ invalidValue: TimeInterval) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.reconnect.maximumDelay = invalidValue
        let invalidConfiguration = configuration
        let endpoint = try #require(URL(string: "ws://example.com"))

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: invalidConfiguration)
        }
    }

    @Test("initialization rejects nonpositive maximum message sizes", arguments: [0, -1, Int.min])
    func rejectInvalidMaximumMessageSize(_ invalidValue: Int) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.maximumMessageSize = invalidValue
        let invalidConfiguration = configuration
        let endpoint = try #require(URL(string: "ws://example.com"))

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: invalidConfiguration)
        }
    }

    @Test("initialization rejects invalid reconnect jitter bounds", arguments: [
        (-1.0) ... 1.0,
        (-Double.infinity) ... 1.0,
        0.0 ... Double.infinity
    ])
    func rejectInvalidJitterRange(_ invalidValue: ClosedRange<TimeInterval>) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.reconnect.jitterRange = invalidValue
        let invalidConfiguration = configuration
        let endpoint = try #require(URL(string: "ws://example.com"))

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: invalidConfiguration)
        }
    }

    @Test("catalog initialization validates configuration before loading servers")
    func rejectInvalidCatalogConfiguration() async throws {
        let catalogLoadState = CatalogLoadState()
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.connectionTimeout = .nan
        configuration.serverCatalogLoader = .init { _, _ in
            await catalogLoadState.recordLoad()
            throw SwiftFulcrum.Client.Error.transport(.setupFailed)
        }
        let invalidConfiguration = configuration

        await expectInvalidConfiguration {
            try await SwiftFulcrum.Client(configuration: invalidConfiguration)
        }
        #expect(await catalogLoadState.hasLoaded == false)
    }

    @Test("zero reconnect timing and unlimited attempts remain valid", arguments: [0, -1])
    func acceptZeroReconnectTimingAndUnlimitedAttempts(_ maximumAttempts: Int) async throws {
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.connectionTimeout = 0
        configuration.reconnect = .init(
            maximumReconnectionAttempts: maximumAttempts,
            reconnectionDelay: 0,
            maximumDelay: 0,
            jitterRange: 0 ... 0
        )
        let endpoint = try #require(URL(string: "ws://example.com"))

        let client = try await SwiftFulcrum.Client(connectingTo: endpoint, configuration: configuration)
        await client.stop()
    }

    @Test("maximum accepted timing interval can be scheduled safely")
    func scheduleMaximumAcceptedTimingInterval() async throws {
        let maximumInterval = SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds
        var configuration = SwiftFulcrum.Client.Configuration()
        configuration.connectionTimeout = maximumInterval
        configuration.reconnect.reconnectionDelay = maximumInterval
        configuration.reconnect.maximumDelay = maximumInterval
        let endpoint = try #require(URL(string: "ws://example.com"))

        let client = try await SwiftFulcrum.Client(
            connectingTo: endpoint,
            configuration: configuration
        )
        await client.stop()

        let sleeper = Task {
            try await Task.sleep(for: .seconds(maximumInterval))
        }
        try await Task.sleep(for: .milliseconds(10))
        sleeper.cancel()
        await #expect(throws: CancellationError.self) {
            try await sleeper.value
        }
    }

    @Test("invalid configuration errors compare by reason")
    func compareInvalidConfigurationErrorsByReason() {
        let left = SwiftFulcrum.Client.Error.client(.invalidConfiguration("reason"))
        let matching = SwiftFulcrum.Client.Error.client(.invalidConfiguration("reason"))
        let different = SwiftFulcrum.Client.Error.client(.invalidConfiguration("other"))

        #expect(left == matching)
        #expect(left != different)
    }

    private func expectInvalidConfiguration(
        _ operation: @Sendable () async throws -> SwiftFulcrum.Client
    ) async {
        do {
            let client = try await operation()
            await client.stop()
            Issue.record("Expected invalid client configuration")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .client(.invalidConfiguration(let reason)) = error else {
                Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                return
            }
            #expect(!reason.isEmpty)
        } catch {
            Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
        }
    }
}
