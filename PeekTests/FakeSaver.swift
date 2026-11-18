import Foundation
@testable import Peek

actor FakeSaver: PhotoSaving {
    private let error: PhotoSaveError?
    private(set) var saved: [[Data]] = []

    init(error: PhotoSaveError? = nil) {
        self.error = error
    }

    /// The size of each saved video, in bytes.
    private(set) var savedVideos: [Int] = []

    func saveVideo(at url: URL) throws {
        if let error {
            throw error
        }
        savedVideos.append((try? Data(contentsOf: url).count) ?? 0)
    }

    func save(_ photos: [Data]) throws {
        if let error {
            throw error
        }
        saved.append(photos)
    }
}
