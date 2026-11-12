/// A recoverable capture error. The session stays on the same slot and offers a retry.
public struct CaptureFailure: Equatable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}
