/// The countdown choices from PRD FR-01: three seconds, five seconds, or manual capture.
public enum CountdownLength: Int, Sendable, Codable, CaseIterable {
    case manual = 0
    case three = 3
    case five = 5

    public var seconds: Int {
        rawValue
    }
}
