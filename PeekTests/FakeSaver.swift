import Foundation
@testable import Peek

actor FakeSaver: PhotoSaving {
    private let error: PhotoSaveError?
    private(set) var saved: [[Data]] = []

    init(error: PhotoSaveError? = nil) {
        self.error = error
    }

    func save(_ photos: [Data]) throws {
        if let error {
            throw error
        }
        saved.append(photos)
    }
}
