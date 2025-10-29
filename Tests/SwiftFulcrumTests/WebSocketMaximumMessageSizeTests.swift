import Foundation
import Testing
import SwiftFulcrum

@Suite(
    "WebSocket maximum message size",
    .serialized,
    .timeLimit(.minutes(5))
)
struct WebSocketMaximumMessageSizeTests {
    private let address = "qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"
    
    @Test("address history fails when maximum message size is too small")
    func addressHistoryFailsWithSmallMaximumMessageSize() async {
        let didSucceed = await fetchHistory(maximumMessageSize: 1 * 1024)
        #expect(Bool(didSucceed == false), "Expected address history call to fail when maximum message size is too small.")
    }
    
    @Test("address history succeeds with default maximum message size")
    func addressHistorySucceedsWithDefaultMaximumMessageSize() async {
        let didSucceed = await fetchHistory(maximumMessageSize: WebSocket.Configuration.defaultMaximumMessageSize)
        #expect(didSucceed, "Expected address history call to succeed with default maximum message size.")
    }
    
    private func fetchHistory(maximumMessageSize: Int) async -> Bool {
        do {
            let configuration = Fulcrum.Configuration(maximumMessageSize: maximumMessageSize)
            let fulcrum = try await Fulcrum(configuration: configuration)
            do {
                try await fulcrum.start()
            } catch {
                Task { await fulcrum.stop() }
                throw error
            }
            
            defer { Task { await fulcrum.stop() } }
            
            let response = try await fulcrum.submit(
                method: .blockchain(
                    .address(
                        .getHistory(
                            address: address,
                            fromHeight: nil,
                            toHeight: nil,
                            includeUnconfirmed: true
                        )
                    )
                ),
                responseType: Response.Result.Blockchain.Address.GetHistory.self
            )
            
            guard let history = response.extractRegularResponse() else { return false }
            
            return !history.transactions.isEmpty
        } catch {
            print("history fetch error for maximumMessageSize=\(maximumMessageSize):", error)
            return false
        }
    }
}
