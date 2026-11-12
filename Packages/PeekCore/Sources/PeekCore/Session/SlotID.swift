/// A stable identifier for one position in a sequence. It never changes when a slot is retaken.
public struct SlotID: Hashable, Sendable, Codable {
    public let index: Int

    public init(_ index: Int) {
        self.index = index
    }
}
