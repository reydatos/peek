import Foundation
import Observation
import PeekCore

/// One pose of a pack that the customer makes: its name, and the clip and the still picture after a recording.
struct PoseDraft: Identifiable {
    let id = UUID()
    var name = ""
    /// The JPEG bytes of the last frame of the clip.
    var still: Data?
    /// The recorded clip, in the temporary folder until the pack is saved.
    var clipURL: URL?

    var isRecorded: Bool {
        still != nil && clipURL != nil
    }
}

/// The pack that the customer makes in the pack editor. It has the number of poses that a session needs.
@Observable
final class PackDraft {
    var name = ""
    var poses = (0 ..< UserPack.poseCount).map { _ in PoseDraft() }

    /// True when the customer can save the pack: it has a name, and each pose has its clip.
    var isComplete: Bool {
        // The same rule as storage, so a name that storage makes empty is not accepted here.
        !PackFile.cleanName(name).isEmpty && poses.allSatisfy(\.isRecorded)
    }

    /// Puts a new recording in a pose. The clip of the old recording is removed.
    func setRecording(still: Data, clipURL: URL, at index: Int) {
        guard poses.indices.contains(index) else { return }
        if let old = poses[index].clipURL, old != clipURL {
            try? FileManager.default.removeItem(at: old)
        }
        poses[index].still = still
        poses[index].clipURL = clipURL
    }

    /// Removes the clips in the temporary folder: the pack is stored, or the customer left the editor.
    func discard() {
        for pose in poses {
            if let url = pose.clipURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
