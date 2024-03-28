import Foundation

protocol NetworkConnectable {
    var isConnected: Bool { get }
    
    func connect()
    func reconnect() async throws
    func disconnect(with reason: String?)
}
