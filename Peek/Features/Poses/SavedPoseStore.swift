import Foundation

/// Durable storage for the IDs of the saved poses, in the order of the saves.
protocol SavedPoseStore {
    func load() -> [String]
    func save(_ ids: [String])
}

/// Keeps the saved poses in the user defaults of the app. They stay on the device.
struct DefaultsSavedPoseStore: SavedPoseStore {
    private static let key = "savedPoseIDs"

    func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: Self.key) ?? []
    }

    func save(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: Self.key)
    }
}
