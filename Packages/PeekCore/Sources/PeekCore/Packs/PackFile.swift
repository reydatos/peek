import Foundation

/// A pose pack as one file, to send to a different phone.
///
/// The file has a header, a small manifest (JSON), and then the bytes of each picture and clip in order.
/// It has no file names and no paths, so a file from a stranger can not name a place on the phone.
/// A file is not trusted: `init(data:)` checks each size before it reads.
public struct PackFile: Equatable, Sendable {
    public struct Pose: Equatable, Sendable {
        public var name: String
        /// The bytes of the still picture.
        public var still: Data
        /// The bytes of the clip.
        public var clip: Data

        public init(name: String, still: Data, clip: Data) {
            self.name = name
            self.still = still
            self.clip = clip
        }
    }

    public enum Failure: Error, Equatable {
        /// The file is not a pack file.
        case notAPack
        case tooLarge
        /// The file does not have the content that its manifest names.
        case damaged
        case wrongPoseCount
        case badName
    }

    public static let fileExtension = "peekpack"
    /// The largest pack file that the app reads. This is a design value.
    public static let maximumBytes = 40 * 1024 * 1024
    /// The largest number of characters of a pack name or a pose name. This is a design value.
    public static let maximumNameLength = 60
    static let maximumManifestBytes = 16 * 1024
    static let magic = Data("PEEKPACK1\n".utf8)

    public var name: String
    public var poses: [Pose]

    public init(name: String, poses: [Pose]) {
        self.name = name
        self.poses = poses
    }

    private struct Manifest: Codable {
        struct Entry: Codable {
            var name: String
            var stillBytes: Int
            var clipBytes: Int
        }

        var name: String
        var poses: [Entry]
    }

    /// The bytes of the file.
    public func encoded() throws -> Data {
        try Self.check(name: name, poseNames: poses.map(\.name), poseCount: poses.count)
        let manifest = try JSONEncoder().encode(Manifest(
            name: name,
            poses: poses.map { Manifest.Entry(name: $0.name, stillBytes: $0.still.count, clipBytes: $0.clip.count) }
        ))
        guard manifest.count <= Self.maximumManifestBytes else { throw Failure.badName }
        var data = Self.magic
        withUnsafeBytes(of: UInt32(manifest.count).bigEndian) { data.append(contentsOf: $0) }
        data.append(manifest)
        for pose in poses {
            data.append(pose.still)
            data.append(pose.clip)
        }
        guard data.count <= Self.maximumBytes else { throw Failure.tooLarge }
        return data
    }

    /// Reads a file that is not trusted.
    public init(data file: Data) throws {
        guard file.count <= Self.maximumBytes else { throw Failure.tooLarge }
        // The indexes of a slice do not start at 0. All offsets here are from `base`, and no copy of the file is made.
        let data = file
        let base = data.startIndex
        let end = data.endIndex
        let header = Self.magic.count
        guard data.count >= header + 4, data.prefix(header) == Self.magic else { throw Failure.notAPack }
        let length = data[base + header ..< base + header + 4].reduce(0) { $0 << 8 | Int($1) }
        let start = base + header + 4
        guard length > 0, length <= Self.maximumManifestBytes, end - start >= length else { throw Failure.damaged }
        guard let manifest = try? JSONDecoder().decode(Manifest.self, from: data[start ..< start + length]) else {
            throw Failure.damaged
        }
        try Self.check(name: manifest.name, poseNames: manifest.poses.map(\.name), poseCount: manifest.poses.count)

        var offset = start + length
        var poses: [Pose] = []
        for entry in manifest.poses {
            // Each size is checked against the bytes that remain, so a false size can not make a large read.
            guard entry.stillBytes > 0, entry.clipBytes > 0,
                  entry.stillBytes <= end - offset, entry.clipBytes <= end - offset - entry.stillBytes
            else { throw Failure.damaged }
            let still = data.subdata(in: offset ..< offset + entry.stillBytes)
            offset += entry.stillBytes
            let clip = data.subdata(in: offset ..< offset + entry.clipBytes)
            offset += entry.clipBytes
            poses.append(Pose(name: entry.name, still: still, clip: clip))
        }
        // The file ends where the last clip ends.
        guard offset == end else { throw Failure.damaged }
        name = manifest.name
        self.poses = poses
    }

    /// A name that a pack file accepts: no control character, no space at the ends, and not longer than the limit.
    /// The app stores each name in this form, so each stored pack can go into a file.
    public static func cleanName(_ name: String) -> String {
        let scalars = name.unicodeScalars.filter { !isRefused($0) }
        let text = String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: .whitespacesAndNewlines)
        return String(text.prefix(maximumNameLength)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A name has no control character and no line break. Format characters stay: an emoji sequence and some
    /// languages need them.
    private static func isRefused(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .control, .lineSeparator, .paragraphSeparator: true
        default: false
        }
    }

    private static func check(name: String, poseNames: [String], poseCount: Int) throws {
        guard poseCount == UserPack.poseCount else { throw Failure.wrongPoseCount }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Failure.badName }
        for text in [name] + poseNames {
            guard text.count <= maximumNameLength,
                  !text.unicodeScalars.contains(where: isRefused)
            else { throw Failure.badName }
        }
    }
}
