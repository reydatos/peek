import Foundation

/// The durable form of a booth session. Milestone M2 writes this record through `DraftStore`.
public struct SessionRecord: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let templateID: String
    public let templateVersion: Int
    public var countdown: CountdownLength
    public var slots: [Slot]

    public init(id: UUID = UUID(), templateID: String, templateVersion: Int, countdown: CountdownLength, slots: [Slot]) {
        self.id = id
        self.templateID = templateID
        self.templateVersion = templateVersion
        self.countdown = countdown
        self.slots = slots
    }
}
