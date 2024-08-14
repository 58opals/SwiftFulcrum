import XCTest
@testable import SwiftFulcrum

final class MethodTests: XCTestCase {
    var client: Client!
    var webSocket: WebSocket!
    
    override func setUp() {
        super.setUp()
        let servers = WebSocket.Server.samples
        guard let url = servers.randomElement() else { fatalError("No server URL available") }
        webSocket = WebSocket(url: url)
        client = Client(webSocket: webSocket)
    }
    
    override func tearDown() {
        client = nil
        webSocket = nil
        super.tearDown()
    }
    
    private func performRegularTest<JSONRPCResult: Decodable>(
        with request: Request,
        responseType: Response.JSONRPC.Generic<JSONRPCResult>.Type,
        expectationDescription: String = "Client receives response and decodes it successfully",
        timeout: TimeInterval = 5.0
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
                    print(" ↳ This is result: \(result)")
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
    
    private func performSubscriptionTest<NotificationResult: Decodable>(
            with request: Request,
            notificationType: Response.JSONRPC.Generic<NotificationResult>.Type,
            expectedFulfillmentCount: Int = 2,
            expectationDescription: String = "Client receives response and notification successfully",
            timeout: TimeInterval = (1.0 * 60) * 15
        ) async throws {
            let expectation = XCTestExpectation(description: expectationDescription)
            expectation.expectedFulfillmentCount = expectedFulfillmentCount
            
            var receivedInitialResponse = false
            
            client.externalDataHandler = { receivedData in
                XCTAssertNotNil(receivedData, "Received data should not be nil")
                print("\(Date()) Received data: \(String(data: receivedData, encoding: .utf8)!)")
                
                do {
                    if !receivedInitialResponse {
                        let response = try JSONDecoder().decode(notificationType, from: receivedData)
                        
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
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self
        )
    }
    
    func testBlockchainRelayFeeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(
                .relayFee
            ).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.RelayFee>.self
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
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetBalance>.self
        )
    }
    
    func testBlockchainAddressGetFirstUseMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getFirstUse(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetFirstUse>.self
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
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetHistory>.self
        )
    }
    
    func testBlockchainAddressGetMempoolMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getMempool(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetMempool>.self
        )
    }
    
    func testBlockchainAddressGetScriptHashMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .getScriptHash(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetScriptHash>.self
        )
    }
    
    func testBlockchainAddressListUnspentMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .listUnspent(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                             tokenFilter: .include)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.ListUnspent>.self
        )
    }
    
    func testBlockchainAddressSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .subscribe(address: "qq2qjesqhy78k5xznl39tqkyjphegmn5hum4sckvhp")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self
        )
    }
    
    func testBlockchainAddressUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.address(
                .unsubscribe(address: "qq2qjesqhy78k5xznl39tqkyjphegmn5hum4sckvhp")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Unsubscribe>.self
        )
    }
}

extension MethodTests {
    func testBlockchainBlockHeaderMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.block(
                .header(height: 0)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Block.Header>.self
        )
    }
    
    func testBlockchainBlockHeadersMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.block(
                .headers(startHeight: 0, count: 6)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Block.Headers>.self
        )
    }
}

extension MethodTests {
    func testBlockchainHeaderGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.header(
                .get(blockHash: "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Header.Get>.self
        )
    }
}

extension MethodTests {
    func testBlockchainHeadersGetTipMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .getTip
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.GetTip>.self
        )
    }
    
    func testBlockchainHeadersSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .subscribe
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self
        )
    }
    
    func testBlockchainHeadersUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.headers(
                .unsubscribe
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Unsubscribe>.self
        )
    }
}

extension MethodTests {
    func testBlockchainTransactionBroadcastMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .broadcast(rawTransaction: "some raw tx")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Broadcast>.self
        )
    }
    
    func testBlockchainTransactionGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .get(transactionHash: "6f10c40f0163dd5da22f0a880fccbebf5553662c35df31f4f8ffd188d9caa651",
                     verbose: true)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Get>.self
        )
    }
    
    func testBlockchainTransactionGetConfirmedBlockHashMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getConfirmedBlockHash(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                                       includeHeader: true)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash>.self
        )
    }
    
    func testBlockchainTransactionGetHeightMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getHeight(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetHeight>.self
        )
    }
    
    func testBlockchainTransactionGetMerkleMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .getMerkle(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle>.self
        )
    }
    
    func testBlockchainTransactionIDFromPosMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .idFromPos(blockHeight: 0,
                           transactionPosition: 0,
                           includeMerkleProof: true)
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos>.self
        )
    }
    
    func testBlockchainTransactionSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self
        )
    }
    
    func testBlockchainTransactionUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(
                .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            )).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Unsubscribe>.self
        )
    }
}

extension MethodTests {
    func testBlockchainTransactionDSProofGetMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get>.self
        )
    }
    
    func testBlockchainTransactionDSProofListMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .list
            ))).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.List>.self
        )
    }
    
    func testBlockchainTransactionDSProofSubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self
        )
    }
    
    func testBlockchainTransactionDSProofUnsubscribeMethod() async throws {
        try await performRegularTest(
            with: Method.blockchain(.transaction(.dsProof(
                .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Unsubscribe>.self
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
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.UTXO.GetInfo>.self
        )
    }
}

extension MethodTests {
    func testMempoolGetFeeHistogramMethod() async throws {
        try await performRegularTest(
            with: Method.mempool(
                .getFeeHistogram
            ).request,
            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Mempool.GetFeeHistogram>.self
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
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self
        )
    }
    
    func testBlockchainHeadersSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.headers(
                .subscribe
            )).request,
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self
        )
    }
    
    func testBlockchainTransactionSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.transaction(
                .subscribe(transactionHash: "6447aea54bcfe634c0fe579332ad3f99fe7ebbcb69b89b3876241a3c95f1b78e")
            )).request,
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self
        )
    }
    
    func testBlockchainTransactionDSProofSubscribeNotificationMethod() async throws {
        try await performSubscriptionTest(
            with: Method.blockchain(.transaction(.dsProof(
                .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")
            ))).request,
            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self
        )
    }
}
