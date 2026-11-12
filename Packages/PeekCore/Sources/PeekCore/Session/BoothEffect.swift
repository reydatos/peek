/// Work the app layer must do after a state change. The reducer does no I/O.
public enum BoothEffect: Equatable, Sendable {
    case startCountdown(seconds: Int)
    case stopCountdown
    case capture(CaptureToken, SlotID)
    /// The take is no longer referenced. Delete its media.
    case discardTake(Take)
}
