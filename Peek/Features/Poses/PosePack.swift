import SwiftUI

/// A four-shot sequence of poses. PRD FR-05 and FR-06.
struct PosePack: Identifiable {
    let id: String
    let name: LocalizedStringResource
    let isFree: Bool
    let cues: [PoseCue]
}
