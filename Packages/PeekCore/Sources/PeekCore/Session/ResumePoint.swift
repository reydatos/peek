/// Where a paused session continues after an explicit resume.
public enum ResumePoint: Equatable, Sendable {
    case ready
    /// The countdown starts again from its full length. It never continues on its own.
    case countdown
}
