import Foundation

/// The clips and pack files that an earlier run of the app left in the temporary folder.
///
/// A recording stays in the temporary folder until the pack is saved, and the draft of a pack is in memory only.
/// When the app stops with the editor open, nothing removes those clips. They are video of people, so the app
/// removes them when it opens: at that time no draft can use them.
nonisolated enum StaleClips {
    static func remove(in folder: URL = FileManager.default.temporaryDirectory) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "mov" || file.lastPathComponent.hasPrefix("Share-") {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
