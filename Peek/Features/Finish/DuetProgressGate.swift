import Foundation

/// Passes the progress of the duet video on in whole percents, and only when it grows.
/// The video reports each frame on its own queue; the progress bar needs about 100 changes, not each frame.
final nonisolated class DuetProgressGate: @unchecked Sendable {
    private let lock = NSLock()
    private var lastPercent = -1
    private let send: @Sendable (Double) -> Void

    init(send: @escaping @Sendable (Double) -> Void) {
        self.send = send
    }

    /// Takes a value from 0 to 1, and sends it when its whole percent is more than the last one sent.
    func report(_ value: Double) {
        let percent = Int((min(max(value, 0), 1) * 100).rounded(.down))
        let isNew = lock.withLock {
            guard percent > lastPercent else { return false }
            lastPercent = percent
            return true
        }
        if isNew {
            send(Double(percent) / 100)
        }
    }
}
