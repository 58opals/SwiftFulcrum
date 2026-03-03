// WebSocketModel.Reconnector~Delay.swift

import Foundation

extension WebSocketModel.Reconnector {
    func makeDelay(for attempt: Int) -> Duration? {
        guard attempt > 0 else { return nil }

        let base = pow(2.0, Double(attempt)) * configuration.reconnectionDelay
        let capped = min(base, configuration.maximumDelay)
        let jitteredSeconds = capped * jitter(configuration.jitterRange)
        let roundedSeconds = Self.roundToNanosecondPrecision(jitteredSeconds)

        return .seconds(roundedSeconds)
    }

    private static func roundToNanosecondPrecision(_ seconds: Double) -> Double {
        guard seconds.isFinite else { return seconds }

        let nsPerSecond = 1_000_000_000.0
        return (seconds * nsPerSecond).rounded(.toNearestOrAwayFromZero) / nsPerSecond
    }
}
