import XCTest
@testable import SwiftFulcrum

import Combine

final class MethodTests: XCTestCase {
    var client: Client!
    var webSocket: WebSocket!
    var cancellableSubscriptions: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let servers = WebSocket.Server.samples
        guard let url = servers.randomElement() else { fatalError("No server URL available") }
        webSocket = WebSocket(url: url)
        client = Client(webSocket: webSocket)
        cancellableSubscriptions = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        client = nil
        webSocket = nil
        cancellableSubscriptions = nil
        super.tearDown()
    }
    
    private func performRegularTest<JSONRPCResult: Decodable>(
        with request: Request,
        responseType: Response.JSONRPCGeneric<JSONRPCResult>.Type,
        expectationDescription: String = "Client receives response and decodes it successfully",
        timeout: TimeInterval = 10.0
    ) async throws {
        let expectation = XCTestExpectation(description: expectationDescription)
        
        let request = request
        
        client.externalDataHandler = { receivedData in
            XCTAssertNotNil(receivedData, "Received data should not be nil")
            print("\(Date()) Received data: \(String(data: receivedData, encoding: .utf8)!)")
            
            do {
                let response = try JSONDecoder().decode(responseType, from: receivedData)
                XCTAssertEqual(response.jsonrpc, request.jsonrpc)
                XCTAssertEqual(response.id, request.id)
                
                switch try response.getResponseType() {
                case .regular(let result):
                    XCTAssertNotNil(result.result)
                case .subscription:
                    XCTFail("Subscription response not expected")
                case .empty(let id):
                    XCTAssertEqual(id, request.id)
                    print(response)
                case .error(let error):
                    XCTAssertEqual(error.id, request.id)
                    XCTAssertNotNil(error.error)
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed to decode response: \(error)")
            }
        }
        
        try await client.sendRequest(request)
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    private func performSubscriptionTest<SubscribeResult: Decodable, NotificationResult: Decodable>(
            with request: Request,
            responseType: Response.JSONRPCGeneric<SubscribeResult>.Type,
            notificationType: Response.JSONRPCGeneric<NotificationResult>.Type,
            expectationDescription: String = "Client receives response and notification successfully",
            timeout: TimeInterval = (1.0 * 60) * 15
        ) async throws {
            let expectation = XCTestExpectation(description: expectationDescription)
            expectation.expectedFulfillmentCount = 2
            
            var receivedInitialResponse = false
            
            client.externalDataHandler = { receivedData in
                XCTAssertNotNil(receivedData, "Received data should not be nil")
                print("\(Date()) Received data: \(String(data: receivedData, encoding: .utf8)!)")
                
                do {
                    if !receivedInitialResponse {
                        let response = try JSONDecoder().decode(responseType, from: receivedData)
                        
                        XCTAssertEqual(response.jsonrpc, request.jsonrpc)
                        XCTAssertEqual(response.id, request.id)
                        
                        switch try response.getResponseType() {
                        case .regular(let result):
                            XCTAssertNotNil(result.result)
                        case .subscription:
                            XCTFail("Subscription shouldn't be here.")
                        case .empty(let id):
                            XCTAssertEqual(id, request.id)
                        case .error(let error):
                            XCTAssertEqual(error.id, request.id)
                            XCTAssertEqual(error.id, response.id)
                            XCTAssertNotNil(error.error)
                        }
                        
                        receivedInitialResponse = true
                        expectation.fulfill()
                    } else {
                        let notification = try JSONDecoder().decode(notificationType, from: receivedData)
                        
                        XCTAssertEqual(notification.method, request.method)
                        
                        switch try notification.getResponseType() {
                        case .regular(let notification):
                            XCTFail("\(notification.id) is not for the subscription.")
                        case .subscription(let notification):
                            XCTAssertNotNil(notification.methodPath)
                            XCTAssertNotNil(notification.result)
                        case .empty(let id):
                            XCTFail("Empty \(id) is not for the subscription.")
                        case .error(let error):
                            XCTFail("Notification cannot send an error: \(error)")
                        }
                        
                        XCTAssertNotNil(notification.params, "Notification params should not be nil")
                        
                        expectation.fulfill()
                    }
                } catch {
                    XCTFail("Failed to decode response: \(error)")
                }
            }
            
            try await client.sendRequest(request)
            await fulfillment(of: [expectation], timeout: timeout)
        }
}

// MARK: - Regular requests
extension MethodTests {
    func testBlockchainEstimateFeeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(
                .estimateFee(numberOfBlocks: 6)
            ).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.EstimateFeeJSONRPCResult>.self
        )
    }
    
    func testBlockchainRelayFeeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(
                .relayFee
            ).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.RelayFeeJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainAddressGetBalanceMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getBalance(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                            tokenFilter: .include)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.GetBalanceJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressGetFirstUseMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getFirstUse(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.GetFirstUseJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressGetHistoryMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getHistory(address: "",
                            fromHeight: nil,
                            toHeight: nil,
                            includeUnconfirmed: true)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.GetHistoryJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressGetMempoolMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getMempool(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.GetMempoolJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressGetScriptHashMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getScriptHash(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.GetScriptHashJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressListUnspentMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .listUnspent(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                             tokenFilter: .include)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.ListUnspentJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .subscribe(address: "qq2qjesqhy78k5xznl39tqkyjphegmn5hum4sckvhp")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.SubscribeJSONRPCResult>.self
        )
    }
    
    func testBlockchainAddressUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .unsubscribe(address: "qq2qjesqhy78k5xznl39tqkyjphegmn5hum4sckvhp")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.UnsubscribeJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainBlockHeaderMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.block(
                .header(height: 0)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Block.HeaderJSONRPCResult>.self
        )
    }
    
    func testBlockchainBlockHeadersMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.block(
                .headers(startHeight: 0, count: 6)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Block.HeadersJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainHeaderGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.header(
                .get(blockHash: "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Header.GetJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainHeadersGetTipMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .getTip
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Headers.GetTipJSONRPCResult>.self
        )
    }
    
    func testBlockchainHeadersSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .subscribe
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Headers.SubscribeJSONRPCResult>.self
        )
    }
    
    func testBlockchainHeadersUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .unsubscribe
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Headers.UnsubscribeJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainTransactionBroadcastMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .broadcast(rawTransaction: "some raw transaction data")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.BroadcastJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                     verbose: true)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.GetJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionGetConfirmedBlockHashMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getConfirmedBlockHash(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                                       includeHeader: true)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.GetConfirmedBlockHashJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionGetHeightMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getHeight(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.GetHeightJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionGetMerkleMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getMerkle(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.GetMerkleJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionIDFromPosMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .idFromPos(blockHeight: 0,
                           transactionPosition: 0,
                           includeMerkleProof: true)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.IDFromPosJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.SubscribeJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.UnsubscribeJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainTransactionDSProofGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.GetJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionDSProofListMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .list
            ))).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.ListJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionDSProofSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.SubscribeJSONRPCResult>.self
        )
    }
    
    func testBlockchainTransactionDSProofUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.UnsubscribeJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testBlockchainUTXOGetInfoMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.utxo(
                .getInfo(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                         outputIndex: 0)
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.UTXO.GetInfoJSONRPCResult>.self
        )
    }
}

extension MethodTests {
    func testMempoolGetFeeHistogramMethod() async throws {
        try await performRegularTest(
            with: Method.mempool(
                .getFeeHistogram
            ).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Mempool.GetFeeHistogramJSONRPCResult>.self
        )
    }
}

// MARK: - Subscription requests
extension MethodTests {
    func testBlockchainAddressSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.address(
                .subscribe(address: "qq2qjesqhy78k5xznl39tqkyjphegmn5hum4sckvhp")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.SubscribeJSONRPCResult>.self,
            notificationType: Response.JSONRPCGeneric<Response.Result.Blockchain.Address.SubscribeJSONRPCNotification>.self
        )
    }
    
    func testBlockchainHeadersSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.headers(
                .subscribe
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Headers.SubscribeJSONRPCResult>.self,
            notificationType: Response.JSONRPCGeneric<Response.Result.Blockchain.Headers.SubscribeJSONRPCNotification>.self
        )
    }
    
    func testBlockchainTransactionSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.transaction(
                .subscribe(transactionHash: "6447aea54bcfe634c0fe579332ad3f99fe7ebbcb69b89b3876241a3c95f1b78e")
            )).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.SubscribeJSONRPCResult>.self,
            notificationType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.SubscribeJSONRPCNotification>.self
        )
    }
    
    func testBlockchainTransactionDSProofSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.transaction(.dsProof(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.SubscribeJSONRPCResult>.self,
            notificationType: Response.JSONRPCGeneric<Response.Result.Blockchain.Transaction.DSProof.SubscribeJSONRPCNotification>.self
        )
    }
}
