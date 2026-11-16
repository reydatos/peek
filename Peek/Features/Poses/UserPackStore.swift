import Foundation
import PeekCore

/// The one place on the device that holds the packs of the customer.
enum UserPackStore {
    static let shared = FilePackStore(directory: .applicationSupportDirectory.appending(path: "Packs"))
}
