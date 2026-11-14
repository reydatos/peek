/// What the people in the photo see while the booth waits for a shot.
public enum SubjectView: Equatable, Sendable {
    /// The pose reference picture and the cue.
    case reference
    /// The live frame, with a small pose guide.
    case live
}
