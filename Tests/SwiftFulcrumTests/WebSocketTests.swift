import XCTest
@testable import SwiftFulcrum

import Combine

final class WebSocketTests: XCTestCase {
    var webSocket: WebSocket!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let servers = WebSocket.Server.samples
        guard let url = servers.randomElement() else { fatalError() }
        webSocket = WebSocket(url: url)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        webSocket = nil
        cancellables = nil
        super.tearDown()
    }
}

extension WebSocketTests {
    func testWebSocketConnection() async throws {
        let expectation = XCTestExpectation(description: "WebSocket connects successfully")
        webSocket.connect()
        
        try await Task.sleep(for: .seconds(5))
        XCTAssertTrue(self.webSocket.isConnected)
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testWebSocketDisconnection() async throws {
        let expectation = XCTestExpectation(description: "WebSocket disconnects successfully")
        webSocket.connect()
        
        try await Task.sleep(for: .seconds(5))
        self.webSocket.disconnect()
        
        try await Task.sleep(for: .seconds(5))
        XCTAssertFalse(self.webSocket.isConnected)
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testWebSocketReconnect() async throws {
        let expectation = XCTestExpectation(description: "WebSocket reconnects successfully")
        webSocket.connect()
        try await Task.sleep(for: .seconds(5))
        webSocket.disconnect()
        
        do {
            try await Task.sleep(for: .seconds(5))
            try await self.webSocket.reconnect(with: WebSocket.Server.samples.randomElement())
            
            try await Task.sleep(for: .seconds(5))
            XCTAssertTrue(self.webSocket.isConnected)
            expectation.fulfill()
        } catch WebSocket.Error.connection(url: webSocket.url, reason: .alreadyConnected) {
            XCTAssertTrue(true, "Caught alreadyConnected error as expected")
            expectation.fulfill()
        } catch {
            XCTFail("Reconnection failed with unexpected error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
    }
}
