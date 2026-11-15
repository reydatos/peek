import Foundation

/// The request to open the booth: a new session with a pack, or the stored draft.
struct BoothRequest: Identifiable, Hashable {
    let id = UUID()
    let packID: String
    let resumesDraft: Bool
}
