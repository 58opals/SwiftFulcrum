// ClientInterfaceLocalValidator~EndpointValidation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    @Test(
        "requests reject unsafe timeout limits before starting transport",
        arguments: [
            Duration.zero,
            .seconds(-1),
            .seconds(SwiftFulcrum.Client.Configuration.maximumScheduledIntervalSeconds + 1),
            .seconds(Double(Int64.max).nextDown)
        ]
    )
    func rejectUnsafeRequestTimeoutBeforeStartingTransport(
        timeout: Duration
    ) async {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(
            transport: transport,
            protocolNegotiation: .init()
        )
        let client = await SwiftFulcrum.Client(client: networkClient)

        do {
            let _: SwiftFulcrum.Response.Server.Ping = try await client.request(
                SwiftFulcrum.API.server.ping,
                options: .init(timeout: timeout)
            )
            Issue.record("Expected an unsafe call timeout to be rejected")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .client(.invalidConfiguration(let reason)) = error else {
                Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                return
            }
            #expect(reason.contains("Call timeout"))
        } catch {
            Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
        }

        #expect(await transport.sentMessages.isEmpty)
        #expect(await transport.connectionState == .idle)
        await client.stop()
    }

    @Test(
        "Client initialization rejects invalid WebSocket endpoints without echoing raw URLs",
        arguments: [
            "ws:///missing-host",
            "wss://%20"
        ]
    )
    func rejectInvalidWebSocketEndpointWithoutEchoingRawURL(
        invalidEndpointString: String
    ) async throws {
        let invalidEndpoint = try #require(URL(string: invalidEndpointString))

        do {
            let client = try await SwiftFulcrum.Client(connectingTo: invalidEndpoint)
            await client.stop()
            Issue.record("Expected invalid WebSocket endpoint to be rejected during initialization")
        } catch let error as SwiftFulcrum.Client.Error {
            switch error {
            case .client(.invalidURL(let value)):
                #expect(value == "Invalid WebSocket endpoint URL")
                #expect(!value.contains(invalidEndpointString))
                #expect(!value.contains(invalidEndpoint.absoluteString))
            default:
                Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
            }
        } catch {
            Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
        }
    }
}
