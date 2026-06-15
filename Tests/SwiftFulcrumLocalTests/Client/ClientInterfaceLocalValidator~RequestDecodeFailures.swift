// ClientInterfaceLocalValidator~RequestDecodeFailures.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    @Test("Unary request fails on unidentified JSON-RPC error responses", .timeLimit(.minutes(1)))
    func requestFailsOnUnidentifiedJSONRPCErrorResponse() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.request(
                    SwiftFulcrum.API.blockchain.headers.tip,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("request() should fail on an unidentified JSON-RPC error response")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        try await completeProtocolNegotiation(on: transport)

        _ = try await decodeRequestObject(await transport.dequeueOutgoing())
        let errorPayload = try JSONSerialization.data(
            withJSONObject: [
                "jsonrpc": "2.0",
                "id": NSNull(),
                "error": [
                    "code": -32700,
                    "message": "parse error"
                ]
            ]
        )
        await transport.enqueueIncoming(.data(errorPayload))

        let error = await requestTask.value
        guard case .rpc(let rpcError) = error else {
            Issue.record("Expected request() to surface a nil-id RPC error, got \(error)")
            await client.stop()
            return
        }
        #expect(rpcError.id == nil)
        #expect(rpcError.code == -32700)
        #expect(rpcError.message == "JSON-RPC server error message redacted (11 UTF-8 bytes)")
        #expect(rpcError.messageByteCount == 11)

        await client.stop()
    }

    @Test("Unary request surfaces malformed payloads as decode errors", .timeLimit(.minutes(1)))
    func requestSurfacesMalformedPayloadAsDecodeError() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.request(
                    SwiftFulcrum.API.blockchain.headers.tip,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("request() should surface malformed payloads as decode errors")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        try await completeProtocolNegotiation(on: transport)

        let unaryRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let unaryIdentifier = try extractRequestIdentifier(from: unaryRequest)
        let malformedPayload = try TransportTestActor.encodeResponsePayload(
            identifier: unaryIdentifier,
            result: ["height": "not-a-height", "hex": 7]
        )
        await transport.enqueueIncoming(.data(malformedPayload))

        let error = await requestTask.value
        guard case .coding(.decode(let underlyingError?)) = error else {
            Issue.record("Expected request() to surface a decode error, got \(error)")
            await client.stop()
            return
        }
        #expect(underlyingError is ResponseResultDecodeError || underlyingError is DecodingError)

        await client.stop()
    }
}
