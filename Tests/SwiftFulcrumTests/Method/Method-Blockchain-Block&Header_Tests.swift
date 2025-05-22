import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain.Block/Header/Headers – Regular RPCs")
struct MethodBlockchainBlockTests {
    let fulcrum: Fulcrum
    private let height: UInt = 1
    private let knownBlockHash = "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286"
    init() throws { self.fulcrum = try Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        if !(await fulcrum.isRunning) { try await fulcrum.start() }
        return try await body()
    }
}

extension MethodBlockchainBlockTests {
    /// Fulcrum Method: Blockchain.Block.Header
    @Test("block.header → returns 80-byte header & branch info")
    func blockHeader() async throws {
        let header = try await withRunningNode {
            let result = try await fulcrum.submit(
                method: .blockchain(.block(.header(height: height,
                                                   checkpointHeight: 1))),
                responseType: Response.Result.Blockchain.Block.Header.self)
            return result
        }
        
        print(header)
        #expect(header.hex.count == 160)
        
        
        if let proof = header.proof {
            #expect(proof.root.count == 64)
            for node in proof.branch {
                #expect(node.count == 64)
            }
        }
    }
    
    /// Fulcrum Method: Blockchain.Block.Headers
    @Test("block.headers → batch header fetch decodes")
    func blockHeaders() async throws {
        let range = (start: height, count: UInt(10))
        let headers = try await withRunningNode {
            let result = try await fulcrum.submit(
                method: .blockchain(.block(.headers(startHeight: range.start,
                                                    count: range.count,
                                                    checkpointHeight: 0))),
                responseType: Response.Result.Blockchain.Block.Headers.self)
            return result
        }
        
        print(headers)
        #expect(headers.count == range.count)
        #expect(headers.hex.count == Int(headers.count) * 160)
        #expect(headers.max >= headers.count)
    }
    
    /// Fulcrum Method: Blockchain.Header.Get
    @Test("header.get → specific block by hash")
    func headerGet() async throws {
        let header = try await withRunningNode {
            let result = try await fulcrum.submit(
                method: .blockchain(.header(.get(blockHash: knownBlockHash))),
                responseType: Response.Result.Blockchain.Header.Get.self)
            return result
        }
        
        print(header)
        #expect(header.hex.count == 160)
        #expect(header.height > 0)
    }
    
    /// Fulcrum Method: Blockchain.Header.GetTip
    @Test("headers.get_tip → returns current tip information")
    func headersGetTip() async throws {
        let tip = try await withRunningNode {
            let result = try await fulcrum.submit(
                method: .blockchain(.headers(.getTip)),
                responseType: Response.Result.Blockchain.Headers.GetTip.self)
            return result
        }
        
        print(tip)
        #expect(tip.height > 0)
        #expect(tip.hex.count == 160)
    }
}
