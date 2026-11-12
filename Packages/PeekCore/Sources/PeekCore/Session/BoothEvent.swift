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
}
