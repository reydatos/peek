import Foundation

/// Adds finished pictures to the user's photo library.
nonisolated protocol PhotoSaving: Sendable {
    /// Asks for add-only access if needed, then saves each picture. Throws `PhotoSaveError.denied` without access.
    func save(_ photos: [Data]) async throws
}
