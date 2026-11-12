/// A sequence definition. PRD FR-01: prompt order, countdown, and layout. Crop and export sizes come in M3.
public struct Template: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let version: Int
    public let cues: [Cue]
    public let countdown: CountdownLength
    public let layout: Layout

    public init(id: String, version: Int, cues: [Cue], countdown: CountdownLength, layout: Layout) {
        self.id = id
        self.version = version
        self.cues = cues
        self.countdown = countdown
        self.layout = layout
    }
}
