// SwiftFulcrum.Logging.ConsoleAdapter+OutputSink.swift

import Foundation

extension SwiftFulcrum.Logging.ConsoleAdapter {
    public actor OutputSink: Sendable {
        public static let shared = OutputSink()

        private var lastSignature: String?
        private var lastRendered: String?
        private var repeatCount = 0
        private var debounceTask: Task<Void, Never>?
        private let printLine: @Sendable (String) -> Void

        init(printLine: @escaping @Sendable (String) -> Void = { print($0) }) {
            self.printLine = printLine
        }

        func enqueue(rendered: String, signature: String) async {
            if signature == lastSignature {
                repeatCount += 1
                scheduleFlush()
                return
            }

            flushRepeatsIfNeeded()

            lastSignature = signature
            lastRendered = rendered
            printLine(rendered)
        }

        private func scheduleFlush() {
            debounceTask?.cancel()
            let outputSink = self
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(150))
                await outputSink.flushRepeatsIfNeeded()
            }
        }

        private func flushRepeatsIfNeeded() {
            debounceTask?.cancel()
            guard repeatCount > 0 else { return }
            let times = repeatCount
            let repetitionDescriptor = times == 1 ? "1 more time" : "\(times) more times"
            if let lastRendered {
                printLine("↑ previous line repeated \(repetitionDescriptor): \(lastRendered)")
            } else {
                printLine("↑ previous line repeated \(repetitionDescriptor)")
            }
            repeatCount = 0
        }
    }
}
