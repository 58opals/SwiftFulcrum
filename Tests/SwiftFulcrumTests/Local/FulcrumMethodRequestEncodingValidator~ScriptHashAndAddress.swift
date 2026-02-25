import Foundation
import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Encodes scripthash and address request variants")
    func encodeScriptHashAndAddressRequests() throws {
        let scriptHash = String(repeating: "a", count: 64)
        let address = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

        try assertRequest(.blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: nil))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getBalance(scripthash: "", tokenFilter: nil))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: .include))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getBalance(scripthash: "", tokenFilter: .include))).path,
                          expectedParameters: [scriptHash, "include_tokens"])
        try assertRequest(.blockchain(.scripthash(.getFirstUse(scripthash: scriptHash))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getFirstUse(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: 5, toHeight: 10, shouldIncludeUnconfirmed: true))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getHistory(scripthash: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [scriptHash, 5, -1])
        try assertHistoryDefaultUpperBound(
            for: .blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))),
            identifier: scriptHash
        )
        try assertRequest(.blockchain(.scripthash(.getHistory(scripthash: scriptHash, fromHeight: 1, toHeight: 42, shouldIncludeUnconfirmed: false))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getHistory(scripthash: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [scriptHash, 1, 42])
        try assertRequest(.blockchain(.scripthash(.getMempool(scripthash: scriptHash))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.getMempool(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.listUnspent(scripthash: scriptHash, tokenFilter: nil))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.listUnspent(scripthash: "", tokenFilter: nil))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.listUnspent(scripthash: scriptHash, tokenFilter: .only))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.listUnspent(scripthash: "", tokenFilter: .only))).path,
                          expectedParameters: [scriptHash, "tokens_only"])
        try assertRequest(.blockchain(.scripthash(.subscribe(scripthash: scriptHash))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.subscribe(scripthash: ""))).path,
                          expectedParameters: [scriptHash])
        try assertRequest(.blockchain(.scripthash(.unsubscribe(scripthash: scriptHash))),
                          expectedPath: FulcrumMethodRequest.blockchain(.scripthash(.unsubscribe(scripthash: ""))).path,
                          expectedParameters: [scriptHash])

        try assertRequest(.blockchain(.address(.getBalance(address: address, tokenFilter: nil))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getBalance(address: "", tokenFilter: nil))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getBalance(address: address, tokenFilter: .exclude))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getBalance(address: "", tokenFilter: .exclude))).path,
                          expectedParameters: [address, "exclude_tokens"])
        try assertRequest(.blockchain(.address(.getFirstUse(address: address))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getFirstUse(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getHistory(address: address, fromHeight: 7, toHeight: 9, shouldIncludeUnconfirmed: true))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getHistory(address: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [address, 7, -1])
        try assertHistoryDefaultUpperBound(
            for: .blockchain(.address(.getHistory(address: address, fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))),
            identifier: address
        )
        try assertRequest(.blockchain(.address(.getHistory(address: address, fromHeight: 2, toHeight: 33, shouldIncludeUnconfirmed: false))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getHistory(address: "", fromHeight: nil, toHeight: nil, shouldIncludeUnconfirmed: false))).path,
                          expectedParameters: [address, 2, 33])
        try assertRequest(.blockchain(.address(.getMempool(address: address))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getMempool(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.getScriptHash(address: address))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.getScriptHash(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.listUnspent(address: address, tokenFilter: nil))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.listUnspent(address: "", tokenFilter: nil))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.listUnspent(address: address, tokenFilter: .include))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.listUnspent(address: "", tokenFilter: .include))).path,
                          expectedParameters: [address, "include_tokens"])
        try assertRequest(.blockchain(.address(.subscribe(address: address))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.subscribe(address: ""))).path,
                          expectedParameters: [address])
        try assertRequest(.blockchain(.address(.unsubscribe(address: address))),
                          expectedPath: FulcrumMethodRequest.blockchain(.address(.unsubscribe(address: ""))).path,
                          expectedParameters: [address])
    }
}

private extension FulcrumMethodRequestEncodingValidator {
    func assertHistoryDefaultUpperBound(for method: FulcrumMethodRequest, identifier: String) throws {
        let parameters = try parameters(for: method)
        #expect(parameters.count == 3)
        #expect(parameters[0] as? String == identifier)
        #expect((parameters[1] as? NSNumber)?.uint64Value == 0)
        #expect((parameters[2] as? NSNumber)?.uint64Value == UInt64.max)
    }
}
