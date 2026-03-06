import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("connection state stream multicasts idle/connected/disconnected to every subscriber", .timeLimit(.minutes(1)))
    func multicastConnectionStateLifecycleToMultipleSubscribers() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        
        let firstStream = await fulcrum.makeConnectionStateStream()
        let secondStream = await fulcrum.makeConnectionStateStream()
        
        let firstCollector = Task {
            await collectConnectionStates(from: firstStream, count: 2, timeout: .seconds(2))
        }
        let secondCollector = Task {
            await collectConnectionStates(from: secondStream, count: 2, timeout: .seconds(2))
        }
        
        try await startAndNegotiate(fulcrum, transport: transport)
        await fulcrum.stop()
        
        let firstStates = await firstCollector.value
        let secondStates = await secondCollector.value
        
        #expect(firstStates == secondStates)
        #expect(firstStates.first == .idle)
        #expect(firstStates.contains(.connected))
        #expect(await fulcrum.isRunning == false)
    }
    
    @Test("stop wins when called during in-flight start", .timeLimit(.minutes(1)))
    func stopWinsWhenCalledDuringInFlightStart() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(250))
        
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        
        let startTask = Task { try await fulcrum.start() }
        
        try await Task.sleep(for: .milliseconds(30))
        await fulcrum.stop()
        
        do {
            try await startTask.value
        } catch is CancellationError {
            // The in-flight start may be cancelled by stop().
        } catch let error as SwiftFulcrum.Client.Error {
            if case .transport(.connectionClosed) = error {
                // The transport may close during the stop() path.
            } else {
                Issue.record("Unexpected Fulcrum error from start(): \(error)")
            }
        } catch {
            Issue.record("Unexpected error from start(): \(error)")
        }
        
        #expect(await fulcrum.isRunning == false)
        #expect(await fulcrum.connectionState != .connected)
    }

}
