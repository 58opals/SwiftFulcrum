// SwiftFulcrum.Logging+Level.swift

import Foundation

extension SwiftFulcrum.Logging {
    public enum Level: Sendable {
        case trace
        case debug
        case info
        case notice
        case warning
        case error
        case critical

        var name: String {
            switch self {
            case .trace: return "trace"
            case .debug: return "debug"
            case .info: return "info"
            case .notice: return "notice"
            case .warning: return "warning"
            case .error: return "error"
            case .critical: return "critical"
            }
        }

        var priority: Int {
            switch self {
            case .trace: return 0
            case .debug: return 1
            case .info: return 2
            case .notice: return 3
            case .warning: return 4
            case .error: return 5
            case .critical: return 6
            }
        }
    }
}
