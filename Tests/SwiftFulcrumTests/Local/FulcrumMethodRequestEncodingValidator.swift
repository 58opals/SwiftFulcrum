import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumMethodRequestEncodingValidator {
    func assertRequest(
        _ method: FulcrumMethodRequest,
        expectedPath: String,
        expectedParameters: [Any]
    ) throws {
        let object = try requestObject(for: method)
        #expect(object["method"] as? String == expectedPath)

        let parameters = try #require(object["params"])
        let actualJSON = try canonicalJSONString(for: parameters)
        let expectedJSON = try canonicalJSONString(for: expectedParameters)
        #expect(actualJSON == expectedJSON)
    }

    func requestObject(for method: FulcrumMethodRequest) throws -> [String: Any] {
        let request = method.createRequest(with: UUID())
        let payload = try #require(request.data)
        let object = try #require(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        #expect(object["jsonrpc"] as? String == "2.0")
        #expect(object["id"] as? String != nil)
        return object
    }

    func parameters(for method: FulcrumMethodRequest) throws -> [Any] {
        let object = try requestObject(for: method)
        return try #require(object["params"] as? [Any])
    }

    private func canonicalJSONString(for value: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
