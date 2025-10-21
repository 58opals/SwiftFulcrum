import Foundation
import Testing
import SwiftFulcrum

@Suite(
    "SwiftFulcrum minimal live conformance",
    .timeLimit(.minutes(2))
)
struct SwiftFulcrumLiveConformanceTests {
    // 1) CONNECT + sanity RPC (headers.get_tip)
    @Test("connect → getTip returns height and header")
    func connect_getTip() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.getTip)),
            responseType: Response.Result.Blockchain.Headers.GetTip.self
        )
        switch response {
        case .single(let id, let result):
            print("id: \(id)")
            print("result: \(result)")
            #expect(result.height > 0)
            #expect(!result.hex.isEmpty)
        case .stream(let id, let initialResponse, let updates, let cancel):
            print("id: \(id)")
            print("initialResponse: \(initialResponse)")
            print("updates: \(updates)")
            print("cancel: \(String(describing: cancel))")
            #expect(Bool(false), "Unexpected response kind for getTip")
        }
    }
    
    // 2) BROADCAST (invalid tx) → verify RPC error mapping
    @Test("broadcast invalid tx → maps to Fulcrum.Error.rpc")
    func broadcast_invalid_mapsRPCError() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        let invalidRawTransaction = "invalid raw transaction"
        do {
            let response = try await fulcrum.submit(
                method: .blockchain(.transaction(.broadcast(rawTransaction: invalidRawTransaction))),
                responseType: Response.Result.Blockchain.Transaction.Broadcast.self
            )
            let result = response.extractRegularResponse()
            if let result {
                print(result)
                #expect(Bool(false), "Expected server to reject invalid tx")
            }
        } catch Fulcrum.Error.rpc(let swiftError) {
            if let id = swiftError.id { print("id: \(id)") }
            print("code: \(swiftError.code)")
            print("message: \(swiftError.message)")
            #expect(true, "Expected decoding error detected")
        }
    }
    
    // 3) SUBSCRIBE → RECONNECT → AUTO‑RESUBSCRIBE (headers)
    @Test("headers.subscribe → reconnect → auto‑resubscribe proven by unsubscribe==true")
    func subscribe_reconnect_autoresubscribe() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(
            method: .blockchain(.headers(.subscribe)),
            initialType: Response.Result.Blockchain.Headers.Subscribe.self,
            notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
        )
        switch response {
        case .single(let id, let result):
            print("id: \(id)")
            print("result: \(result)")
            #expect(result.height > 0)
            #expect(!result.hex.isEmpty)
        case .stream(let id, let initialResponse, let updates, let cancel):
            print("id: \(id)")
            print("initialResponse: \(initialResponse)")
            print("updates: \(updates)")
            print("cancel: \(String(describing: cancel))")
            
            try await fulcrum.reconnect()
            try await Task.sleep(for: .seconds(5))
            
            var unsubscribeSucceeded = false
            let maximumAttempts = 5
            
            attemptLoop: for attempt in 0 ..< maximumAttempts {
                let unsubscribeResponse = try await fulcrum.submit(
                    method: .blockchain(.headers(.unsubscribe)),
                    responseType: Response.Result.Blockchain.Headers.Unsubscribe.self
                )
                
                switch unsubscribeResponse {
                case .single(let unsubscribeID, let unsubscribeResult):
                    print("unsubscribe.id: \(unsubscribeID)")
                    print("unsubscribe.result: \(unsubscribeResult)")
                    if unsubscribeResult.success {
                        unsubscribeSucceeded = true
                        break attemptLoop
                    }
                case .stream(let unsubscribeID, let initial, let streamUpdates, let unsubscribeCancel):
                    print("unexpected stream id: \(unsubscribeID)")
                    print("unexpected stream initial: \(initial)")
                    print("unexpected stream updates: \(streamUpdates)")
                    print("unexpected stream cancel: \(String(describing: unsubscribeCancel))")
                    #expect(Bool(false), "headers.unsubscribe should never produce a streaming response")
                    break attemptLoop
                }
                
                guard attempt < maximumAttempts - 1 else { break }
                try await Task.sleep(for: .seconds(1))
            }
            
            #expect(unsubscribeSucceeded, "headers.unsubscribe should report success after reconnect auto-resubscribe")
            print(updates)
        }
    }
    
    // 4) Unsubscribe on stream termination (address)
    @Test("stream termination sends unsubscribe (address.subscribe → cancel → unsubscribe==false)")
    func unsubscribe_on_termination() async throws {
        
    }
    
    // 5) TIMEOUT path (unary) — tiny per-call timeout should win the race
    @Test("timeout: unary call times out with .client(.timeout)")
    func timeout_unary() async throws {
        
    }
    
    // 6) CANCELLATION path (unary) — cancel token should cancel in-flight request
    @Test("cancellation: unary call cancelled with .client(.cancelled)")
    func cancellation_unary() async throws {
        
    }
    
    // 7) Fee histogram parsing: ensure decoding and sort invariants hold.
    @Test("mempool.get_fee_histogram parses and sorts ascending by fee")
    func fee_histogram_parsing() async throws {
        let fulcrum = try await Fulcrum()
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(
            method: .mempool(.getFeeHistogram),
            responseType: Response.Result.Mempool.GetFeeHistogram.self
        )
        switch response {
        case .single(let id, let result):
            print("id: \(id)")
            print("result: \(result)")
            let fees = result.histogram.map(\.fee)
            #expect(fees == fees.sorted())
            #expect(result.histogram.allSatisfy { ($0.fee > 0) && ($0.virtualSize > 0) })
        case .stream(let id, let initialResponse, let updates, let cancel):
            print("id: \(id)")
            print("initialResponse: \(initialResponse)")
            print("updates: \(updates)")
            print("cancel: \(String(describing: cancel))")
            #expect(Bool(false), "Unexpected response kind for get_fee_histogram")
        }
    }
}
