public enum BoothEvent: Equatable, Sendable {
    case finishSetup
    case start
    case tick
    case cancel
    case pause(PauseReason)
    case resume
    case outerDisplayLost
    case captureSucceeded(CaptureToken, Take)
    case captureFailed(CaptureToken, CaptureFailure)
    case accept
    case redo
    case retake(SlotID)
    case undo(SlotID)
    /// Changes the prompt of the current slot. Valid in `ready` only.
    case swapCue(String)
    /// Gives poses to the slots that have no accepted take, in slot order. Valid in `ready` only.
    case assignCues([String])
    /// Changes what the people in the photo see. Valid in `ready` only.
    case showSubject(SubjectView)
}
