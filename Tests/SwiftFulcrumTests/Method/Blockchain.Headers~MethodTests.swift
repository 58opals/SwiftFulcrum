import Testing
import Foundation
import CryptoKit
@testable import SwiftFulcrum

@Suite("Blockchain Headers Method Tests")
struct BlockchainHeadersMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainHeadersMethodTests {
    @Test func testGetTip() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.headers(.getTip)),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.GetTip>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("The Latest Block: \(result)")
    }
}

extension BlockchainHeadersMethodTests {
    @Test func testHeaderSubscribeResponse() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.headers(.subscribe)),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch result {
        case .topHeader(let theLatestBlock):
            print("The Latest Block Height: \(theLatestBlock.height)")
            print("The Latest Block Header(Hex): \(theLatestBlock.hex)")
        case .newHeader(let notification):
            print("New Header: \(notification), but this request should only receive the latest block.")
        }
    }
    
    @Test func testHeaderSubscribeNotification() async throws {
        let (id, initialResponse, notifications) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.headers(.subscribe)),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self)
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch initialResponse {
        case .topHeader(let theLatestBlock):
            print("The Latest Block Height: \(theLatestBlock.height)")
            print("The Latest Block Header(Hex): \(theLatestBlock.hex)")
        case .newHeader(let notification):
            print("New Header: \(notification), but this request should only receive the latest block.")
        }
        
        var notificationCount = 0
        let minimumNotifications = 2
        
        for try await notification in notifications {
            print("Subscription Notification: \(notification)")
            
            switch notification {
            case .topHeader(let top):
                print("Top Header: \(top), but this request should only receive notifications.")
            case .newHeader(let newBlock):
                for block in newBlock {
                    print("New Block Height: \(block.height)")
                    print("New Block Header(Hex): \(block.hex)")
                    notificationCount += 1
                }
            }
            
            if notificationCount >= minimumNotifications {
                #expect(true, "Received \(minimumNotifications) notifications as expected. Test passed.")
                break
            }
        }
    }
    
    @Test func testHeaderUnsubscribeResponse() async throws {
        let (subscriptionID, initialResponse, notifications) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.headers(.subscribe)),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self)
        
        try #require(UUID(uuidString: subscriptionID.uuidString) != nil, "The ID \(subscriptionID.uuidString) is not a valid UUID.")
        
        print("The initial response: \(initialResponse)")
        print("And following subscription responses will be sent through: \(notifications)")
        
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.headers(.unsubscribe)),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Unsubscribe>.self)
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Unsubscribe Response: \(result)")
    }
}
