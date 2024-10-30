import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Address Method Tests")
struct BlockchainAddressMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainAddressMethodTests {
    @Test func testAddressGetBalance() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.getBalance(address: "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve", tokenFilter: nil))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetBalance>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(result.confirmed >= 0, "Confirmed balance should be non-negative.")
        #expect(result.unconfirmed >= 0, "Unconfirmed balance should be zero or positive.")
        
        print("Confirmed Balance: \(result.confirmed), Unconfirmed Balance: \(result.unconfirmed)")
    }
    
    @Test func testAddressGetFirstUse() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.getFirstUse(address: "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetFirstUse>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(result.block_hash.count == 64, "Block hash should be 64 hexadecimal characters.")
        #expect(result.block_hash.range(of: "^[0-9a-fA-F]{64}$", options: .regularExpression) != nil, "Block hash should contain only hexadecimal characters.")
        #expect(result.height > 0, "Height should be greater than zero.")
        #expect(result.tx_hash.count == 64, "Transaction hash should be 64 hexadecimal characters.")
        #expect(result.tx_hash.range(of: "^[0-9a-fA-F]{64}$", options: .regularExpression) != nil, "Transaction hash should contain only hexadecimal characters.")
        
        print("Block Hash: \(result.block_hash), Height: \(result.height), Tx Hash: \(result.tx_hash)")
    }
    
    @Test func testAddressGetHistory() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.getHistory(address: "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve",
                                                 fromHeight: nil,
                                                 toHeight: nil,
                                                 includeUnconfirmed: true))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetHistory>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(!result.isEmpty, "History should contain at least one transaction.")
        for item in result {
            #expect(item.height >= 0, "Transaction height should be non-negative.")
            #expect(item.tx_hash.count == 64, "Transaction hash should be 64 hexadecimal characters.")
            #expect(item.tx_hash.range(of: "^[0-9a-fA-F]{64}$", options: .regularExpression) != nil, "Transaction hash should contain only hexadecimal characters.")
            
            if let fee = item.fee {
                #expect(fee >= 0, "Transaction fee should be non-negative.")
            }
        }
        
        print("History: \(result)")
    }
    
    @Test func testAddressGetMempool() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.getMempool(address: "qq4td0mvtqelg85tg8l4u57waq649ejzuc5cl40use"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetMempool>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Mempool: \(result)")
    }
    
    @Test func testAddressGetScriptHash() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.getScriptHash(address: "qq4td0mvtqelg85tg8l4u57waq649ejzuc5cl40use"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetScriptHash>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Script Hash: \(result)")
    }
    
    @Test func testAddressListUnspent() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.listUnspent(address: "qq4td0mvtqelg85tg8l4u57waq649ejzuc5cl40use",
                                                  tokenFilter: nil))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.ListUnspent>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Unspent List: \(result)")
    }
}

extension BlockchainAddressMethodTests {
    @Test func testAddressSubscribeResponse() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.subscribe(address: "qq4td0mvtqelg85tg8l4u57waq649ejzuc5cl40use"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch result {
        case .status(let status):
            print("Status: \(status)")
        case .addressAndStatus(let addressAndStatus):
            let address = addressAndStatus[0]
            let status = addressAndStatus[1]
            
            print("Address: \(address ?? "none")")
            print("Status: \(status ?? "none")")
        }
    }
    
    @Test func testAddressSubscribeNotification() async throws {
        let address = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"//"qqyy3mss5vmthgnu0m5sm39pcfq8z799ku2nxernca"
        let maximumRetries = 10
        var retryCount = 0
        var subscriptionSuccessful = false
        
        while retryCount < maximumRetries && !subscriptionSuccessful {
            retryCount += 1
            print("Attempt \(retryCount): Subscribing to address \(address)...")
            
            let (id, initialResponse, notifications) = try await fulcrum.submit(
                method:
                    Method
                    .blockchain(.address(.subscribe(address: address))),
                notificationType:
                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self)
            
            try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
            
            switch initialResponse {
            case .status(let status):
                subscriptionSuccessful = true
                print("Status: \(status)")
                
                var notificationCount = 0
                let minimumNotifications = 3
                
                for await notification in notifications {
                    guard let notification else { continue }
                    print("Subscription Notification: \(notification)")
                    
                    switch notification {
                    case .status(let status):
                        print("Status: \(status), but this request should only receive notifications.")
                    case .addressAndStatus(let addressAndStatus):
                        guard let address = addressAndStatus[0] else { fatalError("The address is nil.") }
                        let status = addressAndStatus[1] //guard let status = addressAndStatus[1] else { fatalError("The status is nil.") }
                        
                        print("Address: \(address)")
                        print("Status: \(status ?? "nil")")
                        
                        notificationCount += 1
                    }
                    
                    if notificationCount >= minimumNotifications {
                        #expect(true, "Received \(minimumNotifications) notifications as expected. Test passed.")
                        break
                    }
                }
                
            case .addressAndStatus(let addressAndStatus):
                guard let address = addressAndStatus[0] else { fatalError("The address is nil.") }
                
                if let status = addressAndStatus[1] {
                    subscriptionSuccessful = true
                    print("Address \(address) got the new status \(status), but this request should only receive the status only.")
                } else {
                    print("Status: nil")
                }
                
            case .none:
                print("Status: nil")
                try await Task.sleep(for: .seconds(3))
                let (id, result) = try await fulcrum.submit(
                    method:
                        Method
                        .blockchain(.address(.unsubscribe(address: "qqyy3mss5vmthgnu0m5sm39pcfq8z799ku2nxernca"))),
                    responseType:
                        Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Unsubscribe>.self)
                
                try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
                
                switch result {
                case true:
                    print("Successfully unsubscribed.")
                case false:
                    print("Unsubscription failed.")
                }
            }
        }
        
        if subscriptionSuccessful {
            #expect(true, "Subscribed to address \(address) successfully after \(maximumRetries) attempts.")
        } else {
            #expect(Bool(false), "Failed to subscribe to address \(address) after \(maximumRetries) attempts with `nil` response.")
        }
    }
    
    @Test func testAddressUnsubscribeResponse() async throws {
        let (subscriptionID, initialResponse, notifications) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.address(.subscribe(address: "qqyy3mss5vmthgnu0m5sm39pcfq8z799ku2nxernca"))),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self)
        
        try #require(UUID(uuidString: subscriptionID.uuidString) != nil, "The ID \(subscriptionID.uuidString) is not a valid UUID.")
        
        if let initialResponse {
            print("The initial response: \(initialResponse)")
        } else {
            print("No initial response was received.")
        }
        
        print("And following subscription responses will be sent through: \(notifications)")
        
        var notificationCount = 0
        let minimumNotifications = 1
        
        for await notification in notifications {
            guard let notification else { continue }
            print("Subscription Notification: \(notification)")
            
            switch notification {
            case .status(let status):
                print("Status: \(status), but this request should only receive notifications.")
            case .addressAndStatus(let addressAndStatus):
                guard let address = addressAndStatus[0] else { fatalError("The address is nil.") }
                let status = addressAndStatus[1] //guard let status = addressAndStatus[1] else { fatalError("The status is nil.") }
                
                print("Address: \(address)")
                print("Status: \(status ?? "nil")")
                
                notificationCount += 1
            }
            
            if notificationCount >= minimumNotifications {
                #expect(true, "Received \(minimumNotifications) notifications as expected.")
                
                let (id, result) = try await fulcrum.submit(
                    method:
                        Method
                        .blockchain(.address(.unsubscribe(address: "qqyy3mss5vmthgnu0m5sm39pcfq8z799ku2nxernca"))),
                    responseType:
                        Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Unsubscribe>.self)
                
                try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
                
                switch result {
                case true:
                    print("Successfully unsubscribed.")
                case false:
                    print("Unsubscription failed.")
                }
                
                break
            }
        }
    }
}
