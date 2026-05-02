// FulcrumMethodRequestEncodingValidator~ScriptHashAndAddress.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Encodes scripthash and address request variants")
    func encodeScriptHashAndAddressRequests() throws {
        let scriptHash = String(repeating: "a", count: 64)
        let address = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

        try assertRequest(.blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: nil))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getBalance(scripthash: "", tokenFilter: nil))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: .include))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getBalance(scripthash: "", tokenFilter: .include))).path,
                          expectedParameters: [scriptHash, "include_tokens"])
        try assertRequest(.blockchain(.scripthash(.getFirstUse(scripthash: scriptHash))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getFirstUse(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: 5, toHeight: 10, shouldIncludeUnconfirmed: true))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getHistory(scripthash: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [scriptHash, 5, 10])
        try assertHistoryDefaultUpperBound(
            for: .blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))),
            identifier: scriptHash
        )
        try assertRequest(.blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: 1, toHeight: 42, shouldIncludeUnconfirmed: false))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getHistory(scripthash: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [scriptHash, 1, 42])
        try assertRequest(.blockchain(.scripthash(.getMempool(scripthash: scriptHash))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getMempool(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.listUnspent(scripthash: scriptHash, tokenFilter: nil))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.listUnspent(scripthash: "", tokenFilter: nil))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.listUnspent(scripthash: scriptHash, tokenFilter: .only))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.listUnspent(scripthash: "", tokenFilter: .only))).path,
                          expectedParameters: [scriptHash, "tokens_only"])
        try assertRequest(.blockchain(.scripthash(.subscribe(scripthash: scriptHash))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.subscribe(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.unsubscribe(scripthash: scriptHash))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.scripthash(.unsubscribe(scripthash: ""))).path,
                          expectedParameters: [scriptHash])

        try assertRequest(.blockchain(.address(.getBalance(address: address, tokenFilter: nil))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getBalance(address: "", tokenFilter: nil))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getBalance(address: address, tokenFilter: .exclude))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getBalance(address: "", tokenFilter: .exclude))).path,
                          expectedParameters: [address, "exclude_tokens"])
        try assertRequest(.blockchain(.address(.getFirstUse(address: address))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getFirstUse(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getHistory(address: address, fromHeight: 7, toHeight: 9, shouldIncludeUnconfirmed: true))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getHistory(address: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [address, 7, 9])
        try assertHistoryDefaultUpperBound(
            for: .blockchain(.address(.getHistory(address: address, fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))),
            identifier: address
        )
        try assertRequest(.blockchain(.address(.getHistory(address: address, fromHeight: 2, toHeight: 33, shouldIncludeUnconfirmed: false))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getHistory(address: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [address, 2, 33])
        try assertRequest(.blockchain(.address(.getMempool(address: address))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getMempool(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getScriptHash(address: address))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.getScriptHash(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.listUnspent(address: address, tokenFilter: nil))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.listUnspent(address: "", tokenFilter: nil))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.listUnspent(address: address, tokenFilter: .include))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.listUnspent(address: "", tokenFilter: .include))).path,
                          expectedParameters: [address, "include_tokens"])
        try assertRequest(.blockchain(.address(.subscribe(address: address))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.subscribe(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.unsubscribe(address: address))),
                          expectedPath: SwiftFulcrum.RPC.Method.blockchain(.address(.unsubscribe(address: ""))).path,
                          expectedParameters: [address])
    }
}

private extension FulcrumMethodRequestEncodingValidator {
    func assertHistoryDefaultUpperBound(for method: SwiftFulcrum.RPC.Method, identifier: String) throws {
        let parameters = try parameters(for: method)
        #expect(parameters.count == 3)
        #expect(parameters[0] as? String == identifier)
        #expect((parameters[1] as? NSNumber)?.uint64Value == 0)
        #expect((parameters[2] as? NSNumber)?.uint64Value == UInt64.max)
    }
}
