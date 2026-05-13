// Reconnector~Delay.swift

import Foundation

extension WebSocketConnection.Reconnector {
    func makeDelay(for attempt: Int) -> Duration? {
        guard attempt > 0 else { return nil }

        let base = pow(2.0, Double(attempt)) * configuration.reconnectionDelay
        let capped = min(base, configuration.maximumDelay)
        let jitteredSeconds = capped * jitter(configuration.jitterRange)
        let roundedSeconds = Self.roundToNanosecondPrecision(jitteredSeconds)
        let finalSeconds = min(roundedSeconds, configuration.maximumDelay)

        guard finalSeconds.isFinite, finalSeconds > 0 else { return nil }
        return .seconds(finalSeconds)
    }

    private static func roundToNanosecondPrecision(_ seconds: Double) -> Double {
        let nsPerSecond = 1_000_000_000.0
        return (seconds * nsPerSecond).rounded(.toNearestOrAwayFromZero) / nsPerSecond
    }
}
