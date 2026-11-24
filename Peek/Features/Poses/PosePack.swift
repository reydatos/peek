import SwiftUI

/// A four-shot sequence of poses. PRD FR-05 and FR-06.
struct PosePack: Identifiable {
    let id: String
    let name: PoseName
    /// One short line for the pack card.
    let subtitle: PoseName
    /// The color of the pack: the frame of its pose reference and of its card.
    let accent: Color
    /// The group of the pack. The pose library sorts and filters the packs by it.
    let category: PackCategory
    /// The store product that unlocks the pack, from the table of `StoreProducts`. A free pack has none.
    let productID: String?
    let cues: [PoseCue]

    /// A built-in pack.
    init(
        id: String,
        name: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        accent: Color,
        category: PackCategory,
        isPaid: Bool,
        cues: [PoseCue]
    ) {
        self.id = id
        self.name = .builtIn(name)
        self.subtitle = .builtIn(subtitle)
        self.accent = accent
        self.category = category
        productID = isPaid ? StoreProducts.pack(id) : nil
        self.cues = cues
    }

    /// A customer pack. It is in the group `mine`, and it has the strong color, as the classic booth has.
    /// It is free: making and sharing a pack stays free (owner decision, 2026-11-24).
    init(id: String, name: String, cues: [PoseCue]) {
        self.id = id
        self.name = .custom(name)
        subtitle = .builtIn(.packMineSubtitle)
        accent = PeekTheme.strong
        category = .mine
        productID = nil
        self.cues = cues
    }
}
