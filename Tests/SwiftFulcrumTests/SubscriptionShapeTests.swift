import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Test fixtures / helpers

private struct RegularEnvelope<R: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: UUID
    let result: R
}
private struct RegularEnvelopeOptional<R: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: UUID
    let result: R?
}

private struct SubscriptionEnvelope<P: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let method: String
    let params: P
}
private struct SubscriptionEnvelopeOptional<P: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let method: String
    let params: P?
}

private struct TipEnc: Encodable { let height: UInt; let hex: String }

private struct DSProofEnc: Encodable {
    let dspid: String
    let txid: String
    let hex: String
    let outpoint: Outpoint
    let descendants: [String]
    struct Outpoint: Encodable { let txid: String; let vout: UInt }
}

private struct MixedArray: Encodable {
    enum Item {
        case string(String)
        case uint(UInt)
        case ds(DSProofEnc)
        case null
    }
    let items: [Item]
    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        for i in items {
            switch i {
            case .string(let s): try c.encode(s)
            case .uint(let u): try c.encode(u)
            case .ds(let p): try c.encode(p)
            case .null: try c.encodeNil()
            }
        }
    }
}

@discardableResult
private func expectUnexpectedFormat(_ error: Swift.Error,
                                    contains needle: String,
                                    method: String? = nil) -> Bool {
    guard let e = error as? Response.Result.Error else { Issue.record("wrong error type: \(error)"); return false }
    switch e {
    case .unexpectedFormat(let msg):
        if let method { #expect(msg.contains("[method: \(method)]")) }
        #expect(msg.contains(needle))
        return true
    default:
        Issue.record("expected unexpectedFormat, got \(e)")
        return false
    }
}

@discardableResult
private func expectMissingField(_ error: Swift.Error, _ field: String) -> Bool {
    guard let e = error as? Response.Result.Error else { Issue.record("wrong error type: \(error)"); return false }
    switch e {
    case .missingField(let f):
        #expect(f == field)
        return true
    default:
        Issue.record("expected missingField(\(field)), got \(e)")
        return false
    }
}

private func enc<T: Encodable>(_ v: T) throws -> Data { try JSONRPC.Coder.encoder.encode(v) }

// MARK: - Shape guard tests

@Suite("JSON-RPC subscribe shape guards")
struct SubscriptionShapeTests {
    
    // blockchain.address.subscribe
    @Test
    func address_initial_accepts_status_string() throws {
        let path = Method.blockchain(.address(.subscribe(address: "q..."))).path
        let payload = try enc(RegularEnvelope(id: UUID(), result: "deadbeef"))
        let value = try payload.decode(Response.Result.Blockchain.Address.Subscribe.self,
                                       context: .init(methodPath: path))
        #expect(value.status == "deadbeef")
    }
    
    @Test
    func address_initial_rejects_pair() throws {
        let path = Method.blockchain(.address(.subscribe(address: "q..."))).path
        let payload = try enc(RegularEnvelope(id: UUID(), result: ["qqqq", "abcd"]))
        do {
            _ = try payload.decode(Response.Result.Blockchain.Address.Subscribe.self,
                                   context: .init(methodPath: path))
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Expected a status string", method: path)
        }
    }
    
    @Test
    func address_notification_accepts_pair() throws {
        let path = Method.blockchain(.address(.subscribe(address: "q..."))).path
        let payload = try enc(SubscriptionEnvelope(method: path, params: ["qqqq", "abcd"]))
        let note = try payload.decode(
            Response.Result.Blockchain.Address.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        #expect(note.subscriptionIdentifier == "qqqq")
        #expect(note.status == "abcd")
    }
    
    @Test
    func address_notification_rejects_single_status() throws {
        let path = Method.blockchain(.address(.subscribe(address: "q..."))).path
        let payload = try enc(SubscriptionEnvelope(method: path, params: "deadbeef"))
        do {
            _ = try payload.decode(
                Response.Result.Blockchain.Address.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Expected address and status pair")
        }
    }
    
    // blockchain.headers.subscribe
    @Test
    func headers_initial_accepts_top_or_single() throws {
        let path = Method.blockchain(.headers(.subscribe)).path
        
        // top header
        let p1 = try enc(RegularEnvelope(id: UUID(), result: TipEnc(height: 100, hex: "aa")))
        let r1 = try p1.decode(Response.Result.Blockchain.Headers.Subscribe.self,
                               context: .init(methodPath: path))
        #expect(r1.height == 100 && r1.hex == "aa")
        
        // single new header batch
        let p2 = try enc(RegularEnvelope(id: UUID(), result: [TipEnc(height: 101, hex: "bb")]))
        let r2 = try p2.decode(Response.Result.Blockchain.Headers.Subscribe.self,
                               context: .init(methodPath: path))
        #expect(r2.height == 101 && r2.hex == "bb")
    }
    
    @Test
    func headers_initial_rejects_multi_batch() throws {
        let path = Method.blockchain(.headers(.subscribe)).path
        let payload = try enc(RegularEnvelope(id: UUID(), result: [TipEnc(height: 1, hex: "aa"),
                                                                   TipEnc(height: 2, hex: "bb")]))
        do {
            _ = try payload.decode(Response.Result.Blockchain.Headers.Subscribe.self,
                                   context: .init(methodPath: path))
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Expected single top header", method: path)
        }
    }
    
    @Test
    func headers_notification_accepts_batch_and_rejects_empty() throws {
        let path = Method.blockchain(.headers(.subscribe)).path
        
        // batch ok
        let ok = try enc(SubscriptionEnvelope(method: path,
                                              params: [TipEnc(height: 5, hex: "aa"),
                                                       TipEnc(height: 6, hex: "bb")]))
        let note = try ok.decode(
            Response.Result.Blockchain.Headers.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        
        #expect(note.subscriptionIdentifier == path)
        #expect(note.blocks.count == 2)
        #expect(note.blocks[0].height == 5 && note.blocks[1].height == 6)
        
        // empty batch -> missingField
        let bad = try enc(SubscriptionEnvelope(method: path, params: [TipEnc]()))
        do {
            _ = try bad.decode(
                Response.Result.Blockchain.Headers.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = expectMissingField(error, "header list empty")
        }
    }
    
    // blockchain.transaction.subscribe
    @Test
    func tx_initial_accepts_height_and_rejects_pair() throws {
        let path = Method.blockchain(.transaction(.subscribe(transactionHash: "t"))).path
        
        // ok: height
        let ok = try enc(RegularEnvelope(id: UUID(), result: 42 as UInt))
        let r = try ok.decode(Response.Result.Blockchain.Transaction.Subscribe.self,
                              context: .init(methodPath: path))
        #expect(r.height == 42)
        
        // bad: [txid, height]
        let bad = try enc(RegularEnvelope(id: UUID(),
                                          result: MixedArray(items: [.string("abcd"), .uint(7)])))
        do {
            _ = try bad.decode(Response.Result.Blockchain.Transaction.Subscribe.self,
                               context: .init(methodPath: path))
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Expected a height uint", method: path)
        }
    }
    
    @Test
    func tx_notification_accepts_pair_and_rejects_height_only_and_duplicates() throws {
        let path = Method.blockchain(.transaction(.subscribe(transactionHash: "t"))).path
        
        // ok: [txid, height]
        let ok = try enc(SubscriptionEnvelope(method: path,
                                              params: MixedArray(items: [.string("abcd"), .uint(9)])))
        let note = try ok.decode(
            Response.Result.Blockchain.Transaction.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        #expect(note.subscriptionIdentifier == "abcd")
        #expect(note.transactionHash == "abcd")
        #expect(note.height == 9)
        
        // bad: height only
        let bad1 = try enc(SubscriptionEnvelope(method: path, params: 11 as UInt))
        do {
            _ = try bad1.decode(
                Response.Result.Blockchain.Transaction.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Expected [txid, height]")
        }
        
        // bad: duplicate txid elements
        let bad2 = try enc(SubscriptionEnvelope(method: path,
                                                params: MixedArray(items: [.string("a"), .string("b")])))
        do {
            _ = try bad2.decode(
                Response.Result.Blockchain.Transaction.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error, contains: "Duplicate transaction hash")
        }
    }
    
    // blockchain.transaction.dsproof.subscribe
    @Test
    func dsproof_initial_accepts_proof_and_rejects_pair() throws {
        let path = Method.blockchain(.transaction(.dsProof(.subscribe(transactionHash: "t")))).path
        let proof = DSProofEnc(dspid: "dsp1", txid: "tx1", hex: "00",
                               outpoint: .init(txid: "txo", vout: 1),
                               descendants: ["x"])
        
        // ok: DSProof object
        let ok = try enc(RegularEnvelope(id: UUID(), result: proof))
        let r = try ok.decode(Response.Result.Blockchain.Transaction.DSProof.Subscribe.self,
                              context: .init(methodPath: path))
        #expect(r.proof?.transactionID == "tx1")
        
        // bad: [txid, dsProof] for *initial*
        let bad = try enc(RegularEnvelope(id: UUID(),
                                          result: MixedArray(items: [.string("tx1"), .ds(proof)])))
        do {
            _ = try bad.decode(Response.Result.Blockchain.Transaction.DSProof.Subscribe.self,
                               context: .init(methodPath: path))
            Issue.record("expected failure")
        } catch {
            _ = expectUnexpectedFormat(error,
                                       contains: "Expected DSProof or nil for DSProof.Subscribe initial response",
                                       method: path)
        }
    }
    
    @Test
    func dsproof_notification_accepts_pair_or_proof_only_and_rejects_nil_proof_only() throws {
        let path = Method.blockchain(.transaction(.dsProof(.subscribe(transactionHash: "t")))).path
        let proof = DSProofEnc(dspid: "dsp1", txid: "tx1", hex: "00",
                               outpoint: .init(txid: "txo", vout: 1),
                               descendants: ["x"])
        
        let pair = try enc(SubscriptionEnvelope(method: path,
                                                params: MixedArray(items: [.string("tx1"), .ds(proof)])))
        let n1 = try pair.decode(
            Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        #expect(n1.subscriptionIdentifier == "tx1")
        #expect(n1.transactionHash == "tx1")
        #expect(n1.proof?.transactionID == "tx1")
        
        let solo = try enc(SubscriptionEnvelope(method: path, params: proof))
        let n2 = try solo.decode(
            Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification.self,
            context: .init(methodPath: path)
        )
        #expect(n2.subscriptionIdentifier == "tx1")
        #expect(n2.transactionHash == "tx1")
        #expect(n2.proof?.transactionID == "tx1")
        
        let badNoHash = try enc(SubscriptionEnvelope(method: path,
                                                     params: MixedArray(items: [.ds(proof)])))
        do {
            _ = try badNoHash.decode(
                Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification.self,
                context: .init(methodPath: path)
            )
            Issue.record("expected failure")
        } catch {
            _ = expectMissingField(error, "transactionHash")
        }
    }
}
