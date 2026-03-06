import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct WebSocketLifecycleValidator {
    @Test("WebSocket lifecycle stream multicasts events to each subscriber", .timeLimit(.minutes(1)))
    func multicastLifecycleEventsToAllSubscribers() async {
        let webSocket = WebSocketModel(url: URL(string: "wss://example.invalid")!)
        let firstStream = await webSocket.makeLifecycleEvents()
        let secondStream = await webSocket.makeLifecycleEvents()
        
        let firstCollector = Task {
            await collectLifecycleEventSignatures(from: firstStream, count: 2, timeout: .seconds(2))
        }
        let secondCollector = Task {
            await collectLifecycleEventSignatures(from: secondStream, count: 2, timeout: .seconds(2))
        }
        
        await webSocket.emitLifecycle(.connected(isReconnect: true))
        await webSocket.emitLifecycle(.disconnected(code: .normalClosure, reason: "test"))
        
        let firstEvents = await firstCollector.value
        let secondEvents = await secondCollector.value
        
        #expect(firstEvents == secondEvents)
        #expect(firstEvents == ["connected:true", "disconnected:\(URLSessionWebSocketTask.CloseCode.normalClosure.rawValue):test"])
    }
}

extension WebSocketLifecycleValidator {
    private func collectLifecycleEventSignatures(
        from stream: AsyncStream<WebSocketModel.Lifecycle.Event>,
        count: Int,
        timeout: Duration
    ) async -> [String] {
        let collector = LifecycleEventSignatureCollectorModel(targetCount: count)
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await event in stream {
                    let reachedTarget = await collector.record(event)
                    if reachedTarget {
                        break
                    }
                }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
            }
            _ = await group.next()
            group.cancelAll()
        }
        
        return await collector.snapshot()
    }
}

private actor LifecycleEventSignatureCollectorModel {
    private let targetCount: Int
    private var values: [String] = .init()
    
    init(targetCount: Int) {
        self.targetCount = targetCount
    }
    
    func record(_ event: WebSocketModel.Lifecycle.Event) -> Bool {
        values.append(signature(for: event))
        return values.count >= targetCount
    }
    
    func snapshot() -> [String] {
        values
    }
    
    private func signature(for event: WebSocketModel.Lifecycle.Event) -> String {
        switch event {
        case .connected(let isReconnect):
            return "connected:\(isReconnect)"
        case .disconnected(let code, let reason):
            return "disconnected:\(code.rawValue):\(reason ?? "nil")"
        }
    }
}
