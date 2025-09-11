import Foundation
import Testing
import SwiftFulcrum

@Suite(
    "SwiftFulcrum minimal live conformance",
    .serialized,
    .timeLimit(.minutes(2))
)
struct SwiftFulcrumLiveConformanceTests {
    private var webSocketURLOverride: String? { ProcessInfo.processInfo.environment["FULCRUM_WS_URL"] }
    
    private static let sampleAddress = "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"
    private static let invalidRawTransaction = "00"
    private static let veryShort: Duration = .milliseconds(1)
    
    private func withClient<Response>(
        _ body: (Fulcrum) async throws -> Response
    ) async throws -> Response {
        let client = try await Fulcrum(
            url: webSocketURLOverride,
            configuration: .init(bootstrapServers: nil)
        )
        try await client.start()
        defer { Task { await client.stop() } }
        return try await body(client)
    }
    
    // 1) CONNECT + sanity RPC (headers.get_tip)
    @Test("connect → getTip returns height and header")
    func connect_getTip() async throws {
        try await withClient { fulcrum in
            let response: Fulcrum.RPCResponse<Response.Result.Blockchain.Headers.GetTip, Never> = try await fulcrum.submit(method: .blockchain(.headers(.getTip)))
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
    }
    
    // 2) BROADCAST (invalid tx) → verify RPC error mapping
    @Test("broadcast invalid tx → maps to Fulcrum.Error.rpc")
    func broadcast_invalid_mapsRPCError() async throws {
        try await withClient { fulcrum in
            do {
                let response: Fulcrum.RPCResponse<Response.Result.Blockchain.Transaction.Broadcast, Never> = try await fulcrum.submit(method: .blockchain(.transaction(.broadcast(rawTransaction: Self.invalidRawTransaction))))
                switch response {
                case .single(let id, let result):
                    print("id: \(id)")
                    print("result: \(result)")
                    #expect(Bool(false), "Expected server to reject invalid tx")
                case .stream(let id, let initialResponse, let updates, let cancel):
                    print("id: \(id)")
                    print("initialResponse: \(initialResponse)")
                    print("updates: \(updates)")
                    print("cancel: \(String(describing: cancel))")
                    #expect(Bool(false), "Unexpected response kind for broadcast")
                }
            } catch let error as Fulcrum.Error {
                switch error {
                case .rpc(let server):
                    print("server: \(server)")
                    #expect(!server.message.isEmpty)
                default:
                    #expect(Bool(false), "Expected .rpc error, got \(error)")
                }
            }
        }
    }
    
    // 3) SUBSCRIBE → RECONNECT → AUTO‑RESUBSCRIBE (headers)
    @Test("headers.subscribe → reconnect → auto‑resubscribe proven by unsubscribe==true")
    func subscribe_reconnect_autoresubscribe() async throws {
        try await withClient { fulcrum in
            let response: Fulcrum.RPCResponse<
                Response.Result.Blockchain.Headers.Subscribe,
                Response.Result.Blockchain.Headers.SubscribeNotification
            > = try await fulcrum.submit(method: .blockchain(.headers(.subscribe)))
            
            switch response {
            case .single(let id, let result):
                print("id: \(id)")
                print("result: \(result)")
                #expect(Bool(false), "Expected stream for headers.subscribe")
            case .stream(let id, let initialResponse, let updates, let cancel):
                print("id: \(id)")
                print("initialResponse: \(initialResponse)")
                print("updates: \(updates)")
                print("cancel: \(String(describing: cancel))")
                
                try await fulcrum.reconnect()
                
                let unsubscription: Fulcrum.RPCResponse<Response.Result.Blockchain.Headers.Unsubscribe, Never> = try await fulcrum.submit(method: .blockchain(.headers(.unsubscribe)))
                switch unsubscription {
                case .single(let id, let result):
                    print("id: \(id)")
                    print("result: \(result)")
                    #expect(result.success, "Expected unsubscribe to confirm active subscription after reconnect")
                case .stream(let id, let initialResponse, let updates, let cancel):
                    print("id: \(id)")
                    print("initialResponse: \(initialResponse)")
                    print("updates: \(updates)")
                    print("cancel: \(String(describing: cancel))")
                    #expect(Bool(false), "Unexpected response kind for unsubscribe")
                }
                
                await cancel()
            }
        }
    }
    
    // 4) Unsubscribe on stream termination (address)
    @Test("stream termination sends unsubscribe (address.subscribe → cancel → unsubscribe==false)")
    func unsubscribe_on_termination() async throws {
        try await withClient { fulcrum in
            let response: Fulcrum.RPCResponse<
                Response.Result.Blockchain.Address.Subscribe,
                Response.Result.Blockchain.Address.SubscribeNotification
            > = try await fulcrum.submit(method: .blockchain(.address(.subscribe(address: Self.sampleAddress))))
            
            switch response {
            case .single(let id, let result):
                print("id: \(id)")
                print("result: \(result)")
                #expect(Bool(false), "Expected stream for address.subscribe")
            case .stream(let id, let initialResponse, let updates, let cancel):
                print("id: \(id)")
                print("initialResponse: \(initialResponse)")
                print("updates: \(updates)")
                print("cancel: \(String(describing: cancel))")
                
                await cancel()
                try await Task.sleep(for: .milliseconds(300))
                
                let unsubscription: Fulcrum.RPCResponse<Response.Result.Blockchain.Address.Unsubscribe, Never> = try await fulcrum.submit(method: .blockchain(.address(.unsubscribe(address: Self.sampleAddress))))
                switch unsubscription {
                case .single(let id, let result):
                    print("id: \(id)")
                    print("result: \(result)")
                    #expect(!result.success, "Unsubscribe should be unnecessary after stream termination")
                case .stream(let id, let initialResponse, let updates, let cancel):
                    print("id: \(id)")
                    print("initialResponse: \(initialResponse)")
                    print("updates: \(updates)")
                    print("cancel: \(String(describing: cancel))")
                    #expect(Bool(false), "Unexpected response kind for unsubscribe")
                }
                
                await cancel()
            }
        }
    }
    
    // 5) TIMEOUT path (unary) — tiny per-call timeout should win the race
    @Test("timeout: unary call times out with .client(.timeout)")
    func timeout_unary() async throws {
        try await withClient { fulcrum in
            do {
                let response: Fulcrum.RPCResponse<Response.Result.Blockchain.Headers.GetTip, Never> = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    options: .init(timeout: Self.veryShort)
                )
                print(response)
                #expect(Bool(false), "Expected timeout to win the race")
            } catch let error as Fulcrum.Error {
                if case .client(.timeout(let duration)) = error {
                    #expect(duration == Self.veryShort)
                } else {
                    #expect(Bool(false), "Expected .client(.timeout), got \(error)")
                }
            }
        }
    }
    
    // 6) CANCELLATION path (unary) — cancel token should cancel in-flight request
    @Test("cancellation: unary call cancelled with .client(.cancelled)")
    func cancellation_unary() async throws {
        try await withClient { fulcrum in
            let token = Client.Call.Token()
            let task = Task<Fulcrum.RPCResponse<Response.Result.Blockchain.Headers.GetTip, Never>, Error> {
                let response: Fulcrum.RPCResponse<Response.Result.Blockchain.Headers.GetTip, Never> = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    options: .init(token: token)
                )
                print(response)
                return response
            }
            
            await token.cancel()
            do {
                let value = try await task.value
                print(value)
                #expect(Bool(false), "Expected cancellation error")
            } catch let error as Fulcrum.Error {
                if case .client(.cancelled) = error {
                    print("Client is cancelled.")
                }
                else { #expect(Bool(false), "Expected .client(.cancelled), got \(error)") }
            }
        }
    }
    
    // 7) Fee histogram parsing: ensure decoding and sort invariants hold.
    @Test("mempool.get_fee_histogram parses and sorts ascending by fee")
    func fee_histogram_parsing() async throws {
        try await withClient { fulcrum in
            let response: Fulcrum.RPCResponse<Response.Result.Mempool.GetFeeHistogram, Never> = try await fulcrum.submit(method: .mempool(.getFeeHistogram))
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
}
