/// PRD section 5: a slot stores its prompt, its order, and its accepted take.
public struct Slot: Identifiable, Equatable, Sendable, Codable {
    public let id: SlotID
    public internal(set) var cueID: String
    public internal(set) var acceptedTake: Take?
    /// The take that undo restores.
    public internal(set) var previousTake: Take?

    public init(id: SlotID, cueID: String, acceptedTake: Take? = nil, previousTake: Take? = nil) {
        self.id = id
        self.cueID = cueID
        self.acceptedTake = acceptedTake
        self.previousTake = previousTake
    }
}
