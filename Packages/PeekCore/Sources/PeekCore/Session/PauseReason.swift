public enum PauseReason: Equatable, Sendable {
    case photographer
    case outerDisplayLost
    case interruption
    /// A draft came back after the app closed. PRD section 5: recovery needs an explicit resume.
    case recovered
}
