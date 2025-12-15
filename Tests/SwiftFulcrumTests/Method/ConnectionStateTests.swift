import Foundation
import Testing
@testable import SwiftFulcrum

@Test("WebSocket tracker emits ordered states for start and disconnect")
func webSocketTrackerEmitsStartThroughDisconnect() async {
    var tracker = WebSocket.ConnectionStateTracker()
    let stream = tracker.makeStream()
    
    tracker.update(to: .connecting)
    tracker.update(to: .connected)
    tracker.update(to: .disconnected)
    
    var iterator = stream.makeAsyncIterator()
    let expected: [WebSocket.ConnectionState] = [.idle, .connecting, .connected, .disconnected]
    var received: [WebSocket.ConnectionState] = .init()
    for _ in expected {
        if let state = await iterator.next() {
            received.append(state)
        }
    }
    
    #expect(received == expected)
}

@Test("Tracker ignores duplicates while capturing reconnection flow")
func webSocketTrackerDeduplicatesStates() async {
    var tracker = WebSocket.ConnectionStateTracker()
    let stream = tracker.makeStream()
    
    tracker.update(to: .connecting)
    tracker.update(to: .connecting)
    tracker.update(to: .reconnecting)
    tracker.update(to: .reconnecting)
    tracker.update(to: .connected)
    
    var iterator = stream.makeAsyncIterator()
    let expected: [WebSocket.ConnectionState] = [.idle, .connecting, .reconnecting, .connected]
    var received: [WebSocket.ConnectionState] = .init()
    for _ in expected {
        if let state = await iterator.next() {
            received.append(state)
        }
    }
    
    #expect(received == expected)
}

@Test("Fulcrum publishes derived connection state for lifecycle and reconnect events")
func fulcrumPublishesConnectionState() async throws {
    let fulcrum = try await Fulcrum(url: "ws://example.com")
    let stream = await fulcrum.makeConnectionStateStream()
    var iterator = stream.makeAsyncIterator()
    
    let webSocket = await fulcrum.client.webSocket
    await webSocket.updateConnectionState(.connecting)
    await webSocket.updateConnectionState(.connected)
    await webSocket.updateConnectionState(.reconnecting)
    await webSocket.updateConnectionState(.connecting)
    await webSocket.updateConnectionState(.connected)
    await webSocket.updateConnectionState(.disconnected)
    
    let expected: [Fulcrum.ConnectionState] = [
        .idle,
        .connecting,
        .connected,
        .reconnecting,
        .connecting,
        .connected,
        .disconnected
    ]
    
    var received: [Fulcrum.ConnectionState] = .init()
    for _ in expected {
        if let state = await iterator.next() {
            received.append(state)
        }
    }
    
    #expect(received == expected)
}
