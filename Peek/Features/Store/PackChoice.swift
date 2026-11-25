/// What a tap on a pack card does.
enum PackChoice: Equatable {
    /// The pack is locked: the unlock sheet opens, so the customer sees the poses before paying (3A).
    case unlock
    /// The set has shots: the photographer confirms that they go away.
    case confirmDiscard
    case load

    init(isUnlocked: Bool, hasShots: Bool) {
        self = if !isUnlocked {
            .unlock
        } else if hasShots {
            .confirmDiscard
        } else {
            .load
        }
    }
}
