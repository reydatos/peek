/// PRD section 5 state sequence: setup, ready, countdown, capture pending, review, next slot or complete.
public enum BoothPhase: Equatable, Sendable {
    case setup
    case ready
    case countdown(remaining: Int)
    case paused(resumeTo: ResumePoint, reason: PauseReason)
    case capturePending(CaptureToken)
    /// A captured take that is not accepted yet.
    case review(Take)
    case complete
}
