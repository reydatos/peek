import Foundation
import Photos

/// Saves to the system photo library. PRD FR-04: the app asks for add-only access at save time, not before.
nonisolated struct PhotoLibrarySaver: PhotoSaving {
    func save(_ photos: [Data]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.denied
        }
        try await PHPhotoLibrary.shared().performChanges {
            for data in photos {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
        }
    }
}
