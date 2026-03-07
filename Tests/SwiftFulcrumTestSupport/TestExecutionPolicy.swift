// TestExecutionPolicy.swift

import Foundation

public enum TestExecutionPolicy {
    private static let runNetworkKey = "SWIFTFULCRUM_RUN_NETWORK"
    private static let runNetworkSlowKey = "SWIFTFULCRUM_RUN_NETWORK_SLOW"
    private static let runNetworkSlowLegacyKey = "SWIFTFULCRUM_RUN_LIVE_SLOW"

    public static var shouldRunNetwork: Bool {
        ProcessInfo.processInfo.environment[runNetworkKey] == "1"
    }

    public static var shouldRunNetworkSlow: Bool {
        let environment = ProcessInfo.processInfo.environment
        return shouldRunNetwork
            && (environment[runNetworkSlowKey] == "1" || environment[runNetworkSlowLegacyKey] == "1")
    }

    public static let networkDisabledMessage = "Network tests are opt-in. Set SWIFTFULCRUM_RUN_NETWORK=1 to enable them."
    public static let slowNetworkDisabledMessage = "Slow network tests are disabled. Set SWIFTFULCRUM_RUN_NETWORK=1 and SWIFTFULCRUM_RUN_NETWORK_SLOW=1 (or SWIFTFULCRUM_RUN_LIVE_SLOW=1)."
}
