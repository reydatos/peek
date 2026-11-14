import SwiftUI

/// A four-shot sequence of poses. PRD FR-05 and FR-06.
struct PosePack: Identifiable {
    let id: String
    let name: LocalizedStringResource
    /// One short line for the pack tile.
    let subtitle: LocalizedStringResource
    /// The narrow color bar of the pack tile. The name and the subtitle carry the meaning.
    let accent: Color
    let isFree: Bool
    let cues: [PoseCue]
}
