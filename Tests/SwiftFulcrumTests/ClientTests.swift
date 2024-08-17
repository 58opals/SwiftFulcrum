import XCTest
@testable import SwiftFulcrum

import Combine

final class ClientTests: XCTestCase {
    var client: Client!
    var webSocket: WebSocket!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let serverList = try WebSocket.Server.getServerList()
        guard let url = serverList.randomElement() else { throw WebSocket.Error.initializing(reason: .noURLAvailable, description: "Server list: \(serverList)") }
        webSocket = WebSocket(url: url)
        client = Client(webSocket: webSocket)
    }
    
    override func tearDownWithError() throws {
        client = nil
        webSocket = nil
        try super.tearDownWithError()
    }
}

extension ClientTests {
    func testClientInitialization() async throws {
        let expectation = XCTestExpectation(description: "Client initializes and connects WebSocket successfully")
        
        try await Task.sleep(for: .seconds(5))
        XCTAssertTrue(self.webSocket.isConnected, "WebSocket should be connected")
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testClientSendRequestAndReceiveResponse() async throws {
        let expectation = XCTestExpectation(description: "Client sends request and receives response successfully")
        
        let request = Method.blockchain(.estimateFee(numberOfBlocks: 6)).request
        client.externalDataHandler = { receivedData in
            XCTAssertNotNil(receivedData, "Received data should not be nil")
            print("Received data: \(String(data: receivedData, encoding: .utf8)!)")
            expectation.fulfill()
        }
        
        try await client.sendRequest(request)
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}
