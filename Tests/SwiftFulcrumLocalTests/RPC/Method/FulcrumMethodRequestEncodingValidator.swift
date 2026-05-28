// FulcrumMethodRequestEncodingValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumMethodRequestEncodingValidator {
    func assertRequest(
        _ method: SwiftFulcrum.RPC.Method,
        expectedPath: String,
        expectedParameters: [Any]
    ) throws {
        let object = try makeRequestObject(for: method)
        #expect(object["method"] as? String == expectedPath)

        let parameters = try #require(object["params"])
        let actualJSON = try makeCanonicalJSONString(for: parameters)
        let expectedJSON = try makeCanonicalJSONString(for: expectedParameters)
        #expect(actualJSON == expectedJSON)
    }

    func assertEndpoint<ResponsePayload>(
        _ endpoint: SwiftFulcrum.API.Request<ResponsePayload>,
        expectedPath: String,
        expectedParameters: [Any]
    ) throws {
        try assertRequest(
            endpoint.method,
            expectedPath: expectedPath,
            expectedParameters: expectedParameters
        )
    }

    func assertEndpoint<Initial, Update>(
        _ endpoint: SwiftFulcrum.API.Subscription<Initial, Update>,
        expectedPath: String,
        expectedParameters: [Any]
    ) throws {
        try assertRequest(
            endpoint.method,
            expectedPath: expectedPath,
            expectedParameters: expectedParameters
        )
    }

    func makeRequestObject(for method: SwiftFulcrum.RPC.Method) throws -> [String: Any] {
        let request = method.createRequest(with: UUID())
        let payload = try #require(request.data)
        let object = try #require(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        #expect(object["jsonrpc"] as? String == "2.0")
        #expect(object["id"] as? String != nil)
        return object
    }

    func makeParameters(for method: SwiftFulcrum.RPC.Method) throws -> [Any] {
        let object = try makeRequestObject(for: method)
        return try #require(object["params"] as? [Any])
    }

    private func makeCanonicalJSONString(for value: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
