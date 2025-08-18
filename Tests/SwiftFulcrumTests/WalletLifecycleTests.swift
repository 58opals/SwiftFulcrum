import Testing
import Foundation
@testable import SwiftFulcrum

/// Sample BCH addresses sourced from existing test fixtures.
private enum SampleAddress {
    static let first = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
    static let second = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"
    static let all = [first, second]
}

private enum WalletInitialSetupTestsError: Swift.Error {
    case malformedResponse
}

/// Exercises wallet behavior during the very first launch.
@Suite("Wallet Lifecycle – Initial Setup Mode")
struct WalletInitialSetupTests {
    let fulcrum: Fulcrum
    init() async throws { self.fulcrum = try await Fulcrum() }

    /// Starts Fulcrum, subscribes to multiple addresses and stops.
    @Test("start → subscribe addresses → stop")
    func startSubscribeAndStop() async throws {
        try await fulcrum.start()
        #expect(await fulcrum.isRunning)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for address in SampleAddress.all {
                group.addTask {
                    let subscription = try await fulcrum.submit(
                        method: .blockchain(.address(.subscribe(address: address))),
                        notificationType: Response.Result.Blockchain.Address.Subscribe.self
                    )
                    
                    guard case .stream(_, let initial, _, let cancel) = subscription else { throw WalletInitialSetupTestsError.malformedResponse }
                    #expect(initial.status.count == 64)
                    await cancel()
                }
            }
            try await group.waitForAll()
        }

        await fulcrum.stop()
        #expect(!(await fulcrum.isRunning))
    }
}

/// Verifies balance refresh and update subscriptions for saved addresses.
@Suite("Wallet Lifecycle – Management Mode")
struct WalletManagementModeTests {
    let fulcrum: Fulcrum
    init() async throws { self.fulcrum = try await Fulcrum() }

    /// Loads balances, refreshes them concurrently, subscribes for updates and stops.
    @Test("load balances → refresh concurrently → subscribe → stop")
    func manageExistingAddresses() async throws {
        try await fulcrum.start()
        let addresses = SampleAddress.all

        try await withThrowingTaskGroup(of: Response.Result.Blockchain.Address.GetBalance.self) { group in
            for address in addresses {
                group.addTask {
                    let response: Fulcrum.RPCResponse<Response.Result.Blockchain.Address.GetBalance, Never> =
                        try await fulcrum.submit(method: .blockchain(.address(.getBalance(address: address, tokenFilter: nil))))
                    guard case .single(_, let balance) = response else {
                        throw WalletInitialSetupTestsError.malformedResponse
                    }
                    return balance
                }
            }
            for try await balance in group { #expect(balance.confirmed >= 0) }
        }

        async let refreshA: Fulcrum.RPCResponse<Response.Result.Blockchain.Address.GetBalance, Never> =
            fulcrum.submit(method: .blockchain(.address(.getBalance(address: addresses[0], tokenFilter: nil))))
        async let refreshB: Fulcrum.RPCResponse<Response.Result.Blockchain.Address.GetBalance, Never> =
            fulcrum.submit(method: .blockchain(.address(.getBalance(address: addresses[1], tokenFilter: nil))))

        let refreshed = try await [refreshA, refreshB]
        for response in refreshed {
            guard case .single(_, let balance) = response else { throw WalletInitialSetupTestsError.malformedResponse }
            #expect(balance.confirmed >= 0)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for address in addresses {
                group.addTask {
                    let subscription = try await fulcrum.submit(
                        method: .blockchain(.address(.subscribe(address: address))),
                        notificationType: Response.Result.Blockchain.Address.Subscribe.self
                    )
                    
                    guard case .stream(_, let initial, _, let cancel) = subscription else { throw WalletInitialSetupTestsError.malformedResponse }
                    #expect(initial.status.count == 64)
                    await cancel()
                }
            }
            try await group.waitForAll()
        }

        await fulcrum.stop()
        #expect(!(await fulcrum.isRunning))
    }
}
