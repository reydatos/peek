/// The poses that the photographer chose in the pose tray, in the order of the taps.
/// The first chosen pose goes to the first open slot, the second one to the second open slot.
struct PoseSelection: Equatable {
    private(set) var ids: [String] = []
    /// The numbers of the slots that have no accepted shot, in slot order.
    let openSlots: [Int]

    /// A tap on a chosen pose removes it. A tap on another pose adds it, while an open slot remains.
    mutating func toggle(_ id: String) {
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else if ids.count < openSlots.count {
            ids.append(id)
        }
    }

    /// The number of the slot that the pose goes to. Nil when the pose is not chosen.
    func slotNumber(for id: String) -> Int? {
        ids.firstIndex(of: id).map { openSlots[$0] }
    }
}
