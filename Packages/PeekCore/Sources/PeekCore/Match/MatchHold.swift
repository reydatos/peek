import Foundation

/// The rule of the automatic shutter: the match stays at or above the limit for a time.
/// It is pure. The caller gives the time of each score.
public struct MatchHold: Equatable, Sendable {
    public let limit: Double
    public let duration: TimeInterval
    /// The time of the first score of the run of scores at or above the limit.
    private var start: TimeInterval?

    public init(limit: Double, duration: TimeInterval) {
        self.limit = limit
        self.duration = duration
    }

    /// Takes one score. True when the match has held for the full time. A low score, or no score, starts the wait again.
    public mutating func update(score: Double?, at time: TimeInterval) -> Bool {
        guard let score, score >= limit else {
            start = nil
            return false
        }
        guard let start else {
            start = time
            return duration <= 0
        }
        return time - start >= duration
    }

    /// Starts the wait again: after a shot, a retake, or a change of pose.
    public mutating func reset() {
        start = nil
    }
}
