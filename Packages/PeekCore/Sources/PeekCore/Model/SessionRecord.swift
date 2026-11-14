import Foundation

/// The durable form of a booth session. Milestone M2 writes this record through `DraftStore`.
public struct SessionRecord: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let templateID: String
    public let templateVersion: Int
    public var countdown: CountdownLength
    public var layout: Layout
    public var frame: FrameColor
    public var slots: [Slot]

    public init(
        id: UUID = UUID(),
        templateID: String,
        templateVersion: Int,
        countdown: CountdownLength,
        layout: Layout = .verticalStrip,
        frame: FrameColor = .cream,
        slots: [Slot]
    ) {
        self.id = id
        self.templateID = templateID
        self.templateVersion = templateVersion
        self.countdown = countdown
        self.layout = layout
        self.frame = frame
        self.slots = slots
    }

    /// A draft from an app version before the frame color has no `frame` value. It gets cream paper.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        templateID = try values.decode(String.self, forKey: .templateID)
        templateVersion = try values.decode(Int.self, forKey: .templateVersion)
        countdown = try values.decode(CountdownLength.self, forKey: .countdown)
        layout = try values.decode(Layout.self, forKey: .layout)
        frame = try values.decodeIfPresent(FrameColor.self, forKey: .frame) ?? .cream
        slots = try values.decode([Slot].self, forKey: .slots)
    }
}
