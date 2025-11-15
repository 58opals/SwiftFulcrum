import Foundation
import Testing
@testable import SwiftFulcrum

struct ResponseResultTests {
    private let knownAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"
    
    @Test("converts live address responses into wallet-friendly models", .timeLimit(.minutes(1)))
    func verifyAddressWorkflows() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let balanceMethod = Method.blockchain(.address(.getBalance(address: knownAddress, tokenFilter: nil)))
            let (_, balanceData) = try await send(balanceMethod, via: webSocket, iterator: &iterator)
            
            let balanceJSON = try balanceData.decode(Response.JSONRPC.Result.Blockchain.Address.GetBalance.self)
            let balanceConverted = try balanceData.decode(
                Response.Result.Blockchain.Address.GetBalance.self,
                context: .init(methodPath: balanceMethod.path)
            )
            
            #expect(balanceConverted.confirmed == balanceJSON.confirmed)
            #expect(balanceConverted.unconfirmed == balanceJSON.unconfirmed)
            
            let firstUseMethod = Method.blockchain(.address(.getFirstUse(address: knownAddress)))
            let (_, firstUseData) = try await send(firstUseMethod, via: webSocket, iterator: &iterator)
            
            let firstUseJSON = try firstUseData.decode(Response.JSONRPC.Result.Blockchain.Address.GetFirstUse?.self)
            let firstUseConverted = try firstUseData.decode(
                Response.Result.Blockchain.Address.GetFirstUse.self,
                context: .init(methodPath: firstUseMethod.path)
            )
            
            #expect(firstUseConverted.found == (firstUseJSON != nil))
            if let json = firstUseJSON {
                #expect(firstUseConverted.blockHash == json.block_hash)
                #expect(firstUseConverted.height == json.height)
                #expect(firstUseConverted.transactionHash == json.tx_hash)
            } else {
                #expect(firstUseConverted.blockHash == nil)
                #expect(firstUseConverted.height == nil)
                #expect(firstUseConverted.transactionHash == nil)
            }
            
            let scriptHashMethod = Method.blockchain(.address(.getScriptHash(address: knownAddress)))
            let (_, scriptHashData) = try await send(scriptHashMethod, via: webSocket, iterator: &iterator)
            
            let scriptHashJSON = try scriptHashData.decode(Response.JSONRPC.Result.Blockchain.Address.GetScriptHash.self)
            let scriptHashConverted = try scriptHashData.decode(
                Response.Result.Blockchain.Address.GetScriptHash.self,
                context: .init(methodPath: scriptHashMethod.path)
            )
            
            #expect(scriptHashConverted.scriptHash == scriptHashJSON)
            #expect(!scriptHashConverted.scriptHash.isEmpty)
            
            let historyMethod = Method.blockchain(
                .address(
                    .getHistory(
                        address: knownAddress,
                        fromHeight: nil,
                        toHeight: nil,
                        includeUnconfirmed: true
                    )
                )
            )
            let (_, historyData) = try await send(historyMethod, via: webSocket, iterator: &iterator)
            
            let historyJSON = try historyData.decode(Response.JSONRPC.Result.Blockchain.Address.GetHistory.self)
            let historyConverted = try historyData.decode(
                Response.Result.Blockchain.Address.GetHistory.self,
                context: .init(methodPath: historyMethod.path)
            )
            
            #expect(historyConverted.transactions.count == historyJSON.count)
            
            guard let confirmedJSON = historyJSON.first(where: { $0.height > 0 }) ?? historyJSON.first else {
                Issue.record("Expected at least one history item for address \(knownAddress)")
                return
            }
            
            guard let confirmedConverted = historyConverted.transactions.first(where: { $0.height == confirmedJSON.height && $0.transactionHash == confirmedJSON.tx_hash }) else {
                Issue.record("Expected converted history to include transaction \(confirmedJSON.tx_hash)")
                return
            }
            
            #expect(confirmedConverted.fee == confirmedJSON.fee)
            
            let verboseTransactionMethod = Method.blockchain(
                .transaction(
                    .get(transactionHash: confirmedJSON.tx_hash, verbose: true)
                )
            )
            let (_, verboseTransactionData) = try await send(verboseTransactionMethod, via: webSocket, iterator: &iterator)
            
            let transactionJSON = try verboseTransactionData.decode(Response.JSONRPC.Result.Blockchain.Transaction.Get.self)
            let transactionConverted = try verboseTransactionData.decode(
                Response.Result.Blockchain.Transaction.GetDetailed.self,
                context: .init(methodPath: verboseTransactionMethod.path)
            )
            
            switch transactionJSON {
            case .detailed(let detailed):
                #expect(transactionConverted.blockHash == detailed.blockhash)
                #expect(transactionConverted.confirmations == detailed.confirmations)
                #expect(transactionConverted.hash == detailed.hash)
                #expect(transactionConverted.inputs.count == detailed.vin.count)
                #expect(transactionConverted.outputs.count == detailed.vout.count)
            case .raw:
                Issue.record("Expected detailed transaction payload when verbose flag is true")
            }
            
            let rawTransactionMethod = Method.blockchain(
                .transaction(
                    .get(transactionHash: confirmedJSON.tx_hash, verbose: false)
                )
            )
            let (_, rawTransactionData) = try await send(rawTransactionMethod, via: webSocket, iterator: &iterator)
            
            do {
                _ = try rawTransactionData.decode(
                    Response.Result.Blockchain.Transaction.GetDetailed.self,
                    context: .init(methodPath: rawTransactionMethod.path)
                )
                Issue.record("Expected unexpected format error when decoding raw transaction as detailed model")
            } catch let error as Response.Result.Error {
                switch error {
                case .unexpectedFormat(let message):
                    #expect(message.contains("raw hex string"))
                default:
                    Issue.record("Unexpected error: \(error)")
                }
            }
        }
    }
    
    @Test("highlights mismatched script hash notifications", .timeLimit(.minutes(1)))
    func verifyScriptHashSubscriptionErrors() async throws {
        try await withConnectedWebSocket { webSocket, iterator in
            let scriptHashMethod = Method.blockchain(.address(.getScriptHash(address: knownAddress)))
            let (_, scriptHashData) = try await send(scriptHashMethod, via: webSocket, iterator: &iterator)
            let scriptHashConverted = try scriptHashData.decode(
                Response.Result.Blockchain.Address.GetScriptHash.self,
                context: .init(methodPath: scriptHashMethod.path)
            )
            
            let subscribeMethod = Method.blockchain(.scripthash(.subscribe(scripthash: scriptHashConverted.scriptHash)))
            let (_, subscribeData) = try await send(subscribeMethod, via: webSocket, iterator: &iterator)
            
            let subscribeJSON = try subscribeData.decode(Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe?.self)
            let subscribeConverted = try subscribeData.decode(
                Response.Result.Blockchain.ScriptHash.Subscribe.self,
                context: .init(methodPath: subscribeMethod.path)
            )
            
            switch subscribeJSON {
            case .status(let statusString):
                #expect(subscribeConverted.status == statusString)
            case .scripthashAndStatus(let pair):
                Issue.record("Expected status string in initial subscribe response; received \(pair)")
            case .none:
                #expect(subscribeConverted.status == nil)
            }
            
            do {
                _ = try subscribeData.decode(
                    Response.Result.Blockchain.ScriptHash.SubscribeNotification.self,
                    context: .init(methodPath: subscribeMethod.path)
                )
                Issue.record("Expected unexpected format error when decoding subscribe acknowledgement as notification")
            } catch let formatError as Response.Result.Error {
                switch formatError {
                case .unexpectedFormat(let message):
                    #expect(message.contains("scripthash and status array"))
                default:
                    Issue.record("Unexpected format error: \(formatError)")
                }
            }
            
            let unsubscribeMethod = Method.blockchain(.scripthash(.unsubscribe(scripthash: scriptHashConverted.scriptHash)))
            let (_, unsubscribeData) = try await send(unsubscribeMethod, via: webSocket, iterator: &iterator)
            let unsubscribeConverted = try unsubscribeData.decode(
                Response.Result.Blockchain.ScriptHash.Unsubscribe.self,
                context: .init(methodPath: unsubscribeMethod.path)
            )
            #expect(unsubscribeConverted.success)
        }
    }
    
    private func send(
        _ method: SwiftFulcrum.Method,
        via webSocket: WebSocket,
        iterator: inout AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Iterator
    ) async throws -> (UUID, Data) {
        let identifier = UUID()
        let request = method.createRequest(with: identifier)
        guard let payload = request.data else { throw Fulcrum.Error.coding(.encode(nil)) }
        
        try await webSocket.send(data: payload)
        
        while let message = try await iterator.next() {
            let data: Data
            switch message {
            case .data(let chunk):
                data = chunk
            case .string(let text):
                guard let converted = text.data(using: .utf8) else { continue }
                data = converted
            @unknown default:
                continue
            }
            
            let responseIdentifier = try Response.JSONRPC.extractIdentifier(from: data)
            if case .uuid(let uuid) = responseIdentifier, uuid == identifier {
                return (identifier, data)
            }
        }
        
        throw Fulcrum.Error.client(.protocolMismatch(method.path))
    }
    
    private func withConnectedWebSocket(
        _ operation: (WebSocket, inout AsyncThrowingStream<URLSessionWebSocketTask.Message, Swift.Error>.Iterator) async throws -> Void
    ) async throws {
        let url = try await randomFulcrumURL()
        let webSocket = WebSocket(url: url)
        try await webSocket.connect()
        
        var iterator = await webSocket.makeMessageStream().makeAsyncIterator()
        
        do {
            try await operation(webSocket, &iterator)
        } catch {
            await webSocket.disconnect()
            throw error
        }
        
        await webSocket.disconnect()
    }
}
