public struct BoothState: Equatable, Sendable {
    public internal(set) var slots: [Slot]
    public internal(set) var currentSlotID: SlotID
    public internal(set) var phase: BoothPhase = .setup
    public internal(set) var lastFailure: CaptureFailure?
    public var countdown: CountdownLength

    /// - Precondition: `cueIDs` is not empty.
    public init(cueIDs: [String], countdown: CountdownLength = .three) {
        precondition(!cueIDs.isEmpty, "A session needs at least one slot.")
        slots = cueIDs.enumerated().map { Slot(id: SlotID($0.offset), cueID: $0.element) }
        currentSlotID = SlotID(0)
        self.countdown = countdown
    }

    /// The state of a draft that comes back from storage. It starts in `setup`, at the first open slot.
    ///
    /// - Precondition: the record has one slot or more.
    public init(restoring record: SessionRecord) {
        precondition(!record.slots.isEmpty, "A session needs at least one slot.")
        slots = record.slots
        currentSlotID = record.slots.first { $0.acceptedTake == nil }?.id ?? record.slots[0].id
        countdown = record.countdown
    }

    public var currentSlot: Slot {
        slots[currentSlotID.index]
    }

    /// True when a slot or the review phase still uses the take.
    func references(_ take: Take) -> Bool {
        if case let .review(candidate) = phase, candidate.id == take.id {
            return true
        }
        return slots.contains { $0.acceptedTake?.id == take.id || $0.previousTake?.id == take.id }
    }

    /// Accepts the take for the current slot. Returns the take that fell out of undo history.
    mutating func accept(_ take: Take) -> Take? {
        let dropped = slots[currentSlotID.index].previousTake
        slots[currentSlotID.index].previousTake = slots[currentSlotID.index].acceptedTake
        slots[currentSlotID.index].acceptedTake = take
        return dropped
    }

    /// Moves to the first slot without an accepted take, or completes the session.
    mutating func advance() {
        if let open = slots.first(where: { $0.acceptedTake == nil }) {
            currentSlotID = open.id
            phase = .ready
        } else {
            phase = .complete
        }
    }

    mutating func undo(_ id: SlotID) {
        guard slots.indices.contains(id.index), let previous = slots[id.index].previousTake else { return }
        slots[id.index].previousTake = slots[id.index].acceptedTake
        slots[id.index].acceptedTake = previous
    }
}
