import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Fulcrum Submit Tests")
struct FulcrumSubmitTests {
    let fulcrum: Fulcrum

    init() async throws {
        self.fulcrum = try Fulcrum(url: "wss://dummy.test")
        // try await fulcrum.start()
    }
    
    @Test func testSubmitRegularResponse() async throws {
        let method = Method.blockchain(.relayFee)
        
        let submitTask = Task.detached(priority: .high) {
            return try await self.fulcrum.submit(
                method: method,
                responseType: Response.JSONRPC.Generic<Double>.self
            )
        }
        
        try await Task.sleep(for: .seconds(1))
        
        let dummyUUID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let simulatedResponse: [String: Any] = [
            "jsonrpc": "2.0",
            "id": dummyUUID.uuidString,
            "result": 0.0001
        ]
        let responseData = try JSONSerialization.data(withJSONObject: simulatedResponse, options: [])
        
        await self.fulcrum.client.handleData(responseData)
        
        let (responseID, result) = try await submitTask.value
        #expect(responseID == dummyUUID, "The response ID should match the dummy UUID.")
        #expect(result == 0.0001, "The relay fee result should be 0.0001.")
    }
    
    @Test func testSubmitNotificationResponse() async throws {
        let method = Method.blockchain(.relayFee)
        
        let submitTask = Task.detached(priority: .high) {
            return try await self.fulcrum.submit(
                method: method,
                notificationType: Response.JSONRPC.Generic<Double>.self
            )
        }
        try await Task.sleep(for: .milliseconds(100))
        
        let dummyUUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        
        let initialResponse: [String: Any] = [
            "jsonrpc": "2.0",
            "id": dummyUUID.uuidString,
            "result": 0.0002
        ]
        let initialData = try JSONSerialization.data(withJSONObject: initialResponse, options: [])
        await self.fulcrum.client.handleData(initialData)
        
        let notificationResponse: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method.path,  // subscription responses are keyed by the method name
            "params": 0.0003
        ]
        let notificationData = try JSONSerialization.data(withJSONObject: notificationResponse, options: [])
        await self.fulcrum.client.handleData(notificationData)
        
        let (responseID, initialResult, stream) = try await submitTask.value
        #expect(responseID == dummyUUID, "The response ID should match the dummy UUID.")
        #expect(initialResult == 0.0002, "The initial result should be 0.0002.")
        
        var notificationValue: Double? = nil
        for await value in stream {
            notificationValue = value
            break
        }
        #expect(notificationValue == 0.0003, "The notification stream value should be 0.0003.")
    }
    
    @Test func testSubmitErrorResponse() async throws {
        let method = Method.blockchain(.relayFee)
        
        let submitTask = Task.detached(priority: .high) {
            return try await self.fulcrum.submit(
                method: method,
                responseType: Response.JSONRPC.Generic<Double>.self
            )
        }
        try await Task.sleep(for: .milliseconds(100))
        
        let dummyUUID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!
        let errorResponse: [String: Any] = [
            "jsonrpc": "2.0",
            "id": dummyUUID.uuidString,
            "error": [
                "code": -32000,
                "message": "Simulated error message"
            ]
        ]
        let errorData = try JSONSerialization.data(withJSONObject: errorResponse, options: [])
        await self.fulcrum.client.handleData(errorData)
        
        do {
            _ = try await submitTask.value
            #expect(Bool(false), "Submit should have thrown an error due to the error response.")
        } catch {
            #expect(error.localizedDescription.contains("Simulated error message"), "Error message should contain 'Simulated error message'.")
        }
    }
}
