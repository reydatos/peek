import Foundation

/// One pose that a customer made: a name, a still picture, and a short clip that shows the move.
public struct UserPose: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    /// The name of the still picture in the media folder of the pack.
    public var stillFile: String
    /// The name of the clip in the media folder of the pack. A pose can have no clip.
    public var clipFile: String?

    public init(id: UUID = UUID(), name: String, stillFile: String, clipFile: String? = nil) {
        self.id = id
        self.name = name
        self.stillFile = stillFile
        self.clipFile = clipFile
    }
}

/// A pose pack that a customer made.
public struct UserPack: Codable, Equatable, Sendable, Identifiable {
    /// A session has four shots, so a pack that the booth can use has four poses.
    public static let poseCount = 4

    public var id: UUID
    public var name: String
    public var poses: [UserPose]

    public init(id: UUID = UUID(), name: String, poses: [UserPose]) {
        self.id = id
        self.name = name
        self.poses = poses
    }

    /// True when the booth can use the pack: it has a name and the full number of poses.
    public var isComplete: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && poses.count == Self.poseCount
    }

    /// The names of the media files that the pack uses.
    public var mediaFiles: Set<String> {
        Set(poses.flatMap { [$0.stillFile, $0.clipFile].compactMap(\.self) })
    }
}
