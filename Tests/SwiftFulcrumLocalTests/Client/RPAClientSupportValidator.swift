// RPAClientSupportValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct RPAClientSupportValidator {
    @Test("Supported RPA history requests use the typed client pipeline", .timeLimit(.minutes(1)))
    func requestSupportedRPAHistory() async throws {
        let (client, transport) = try await makeStartedClient()
        let transactionHash =
            "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"

        let requestTask = Task {
            try await client.request(
                SwiftFulcrum.API.blockchain.rpa.history(
                    prefix: "ab",
                    fromHeight: 825_000,
                    toHeight: 825_060
                ),
                options: .init(timeout: .seconds(5))
            )
        }

        let request = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(request["method"] as? String == "blockchain.rpa.get_history")
        #expect(request["params"] as? [AnyHashable] == ["ab", 825_000, 825_060])

        let identifier = try extractRequestIdentifier(from: request)
        let response = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: [["height": 825_000, "tx_hash": transactionHash]]
        )
        await transport.enqueueIncoming(.data(response))

        let history = try await requestTask.value
        #expect(history.transactions.first?.height == 825_000)
        #expect(history.transactions.first?.transactionHash == transactionHash)

        await client.stop()
    }

    @Test("Typed RPA requests reject negotiated protocol 1.5.3", .timeLimit(.minutes(1)))
    func rejectProtocolBeforeCanonicalOrdering() async throws {
        let (client, transport) = try await makeStartedClient(
            negotiatedProtocolVersion: "1.5.3"
        )
        let baselineMessageCount = await transport.sentMessages.count

        let error = await captureClientError {
            _ = try await client.request(
                SwiftFulcrum.API.blockchain.rpa.mempool(prefix: "ab"),
                options: .init(timeout: .seconds(5))
            )
        }

        #expect(
            error == .client(
                .protocolMismatch(
                    "RPA requests require Electrum Cash protocol 1.6.0 or newer."
                )
            )
        )
        #expect(await transport.sentMessages.count == baselineMessageCount)
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }

    @Test("Typed RPA requests require advertised server capability", .timeLimit(.minutes(1)))
    func rejectMissingRPACapability() async throws {
        let (client, transport) = try await makeStartedClient(rpa: nil)
        let baselineMessageCount = await transport.sentMessages.count

        let error = await captureClientError {
            _ = try await client.request(
                SwiftFulcrum.API.blockchain.rpa.mempool(prefix: "ab"),
                options: .init(timeout: .seconds(5))
            )
        }

        #expect(
            error == .client(
                .protocolMismatch("Server does not advertise RPA support.")
            )
        )
        #expect(await transport.sentMessages.count == baselineMessageCount)
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }

    @Test(
        "Typed RPA requests enforce prefix syntax and advertised bit limits",
        arguments: [
            (
                prefix: "g1",
                indexedPrefixBits: 16,
                minimumPrefixBits: 8,
                expectedMessage:
                    "RPA prefix must contain 1 to 4 hexadecimal characters."
            ),
            (
                prefix: "abcde",
                indexedPrefixBits: 16,
                minimumPrefixBits: 8,
                expectedMessage:
                    "RPA prefix must contain 1 to 4 hexadecimal characters."
            ),
            (
                prefix: "a",
                indexedPrefixBits: 16,
                minimumPrefixBits: 8,
                expectedMessage:
                    "RPA prefix is shorter than the server minimum."
            ),
            (
                prefix: "abc",
                indexedPrefixBits: 8,
                minimumPrefixBits: 4,
                expectedMessage:
                    "RPA prefix exceeds the server index width."
            )
        ]
    )
    func enforceRPAPrefixConstraints(
        prefix: String,
        indexedPrefixBits: Int,
        minimumPrefixBits: Int,
        expectedMessage: String
    ) async throws {
        let rpa = RPAFeatureConfiguration(
            indexedPrefixBits: indexedPrefixBits,
            minimumPrefixBits: minimumPrefixBits
        )
        let (client, transport) = try await makeStartedClient(rpa: rpa)
        let baselineMessageCount = await transport.sentMessages.count

        let error = await captureClientError {
            _ = try await client.request(
                SwiftFulcrum.API.blockchain.rpa.mempool(prefix: prefix),
                options: .init(timeout: .seconds(5))
            )
        }

        #expect(error == .client(.protocolMismatch(expectedMessage)))
        #expect(await transport.sentMessages.count == baselineMessageCount)
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }

    @Test(
        "Typed RPA history enforces range and advertised scan constraints",
        arguments: [
            (
                fromHeight: UInt(825_010),
                toHeight: UInt(825_000),
                startingHeight: 825_000,
                historyBlockLimit: 60,
                expectedMessage:
                    "RPA history end height must not precede its start height."
            ),
            (
                fromHeight: UInt(824_999),
                toHeight: UInt(825_000),
                startingHeight: 825_000,
                historyBlockLimit: 60,
                expectedMessage:
                    "RPA history starts below the server indexed height."
            ),
            (
                fromHeight: UInt(825_000),
                toHeight: UInt(825_061),
                startingHeight: 825_000,
                historyBlockLimit: 60,
                expectedMessage:
                    "RPA history interval exceeds the server block limit."
            )
        ]
    )
    func enforceRPAHistoryConstraints(
        fromHeight: UInt,
        toHeight: UInt,
        startingHeight: Int,
        historyBlockLimit: Int,
        expectedMessage: String
    ) async throws {
        let rpa = RPAFeatureConfiguration(
            historyBlockLimit: historyBlockLimit,
            startingHeight: startingHeight
        )
        let (client, transport) = try await makeStartedClient(rpa: rpa)
        let baselineMessageCount = await transport.sentMessages.count

        let error = await captureClientError {
            _ = try await client.request(
                SwiftFulcrum.API.blockchain.rpa.history(
                    prefix: "ab",
                    fromHeight: fromHeight,
                    toHeight: toHeight
                ),
                options: .init(timeout: .seconds(5))
            )
        }

        #expect(error == .client(.protocolMismatch(expectedMessage)))
        #expect(await transport.sentMessages.count == baselineMessageCount)
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }

    @Test("Typed RPA history enforces advertised maximum item count", .timeLimit(.minutes(1)))
    func enforceRPAMaximumHistoryItems() async throws {
        let rpa = RPAFeatureConfiguration(maximumHistoryItems: 1)
        let (client, transport) = try await makeStartedClient(rpa: rpa)

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            await captureClientError {
                _ = try await client.request(
                    SwiftFulcrum.API.blockchain.rpa.history(
                        prefix: "ab",
                        fromHeight: 825_000
                    ),
                    options: .init(timeout: .seconds(5))
                )
            }
        }

        let request = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        let identifier = try extractRequestIdentifier(from: request)
        let response = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: [
                [
                    "height": 825_000,
                    "tx_hash": String(repeating: "a", count: 64)
                ],
                [
                    "height": 825_001,
                    "tx_hash": String(repeating: "b", count: 64)
                ]
            ]
        )
        await transport.enqueueIncoming(.data(response))

        #expect(
            await requestTask.value
                == .client(
                    .protocolMismatch(
                        "RPA history response exceeds the server item limit."
                    )
                )
        )
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }

    @Test("Typed RPA requests preserve explicit cancellation", .timeLimit(.minutes(1)))
    func cancelTypedRPARequest() async throws {
        let (client, transport) = try await makeStartedClient()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            await captureClientError {
                _ = try await client.request(
                    SwiftFulcrum.API.blockchain.rpa.mempool(prefix: "ab"),
                    options: .init(
                        timeout: .seconds(5),
                        cancellation: cancellation
                    )
                )
            }
        }

        let request = try TransportTestActor.decodeJSONObject(
            from: await transport.dequeueOutgoing()
        )
        #expect(request["method"] as? String == "blockchain.rpa.get_mempool")

        await cancellation.cancel()

        #expect(await requestTask.value == .client(.cancelled))
        #expect(await client.makeInflightUnaryCallCount() == 0)

        await client.stop()
    }
}
