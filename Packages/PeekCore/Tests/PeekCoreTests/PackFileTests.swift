import Foundation
@testable import PeekCore
import Testing

struct PackFileTests {
    private func pack(name: String = "Beach day") -> PackFile {
        PackFile(name: name, poses: (1 ... UserPack.poseCount).map { index in
            PackFile.Pose(name: "Pose \(index)", still: Data("still \(index)".utf8), clip: Data(repeating: UInt8(index), count: 100 * index))
        })
    }

    /// The bytes of a file with a manifest that the test writes.
    private func file(manifest: String, media: Data) -> Data {
        var data = PackFile.magic
        withUnsafeBytes(of: UInt32(manifest.utf8.count).bigEndian) { data.append(contentsOf: $0) }
        data.append(Data(manifest.utf8))
        data.append(media)
        return data
    }

    private func manifest(sizes: [(Int, Int)], name: String = "A") -> String {
        let poses = sizes.map { #"{"name":"p","stillBytes":\#($0.0),"clipBytes":\#($0.1)}"# }.joined(separator: ",")
        return #"{"name":"\#(name)","poses":[\#(poses)]}"#
    }

    @Test func aPackComesBackTheSameFromItsFile() throws {
        let pack = pack()
        #expect(try PackFile(data: pack.encoded()) == pack)
    }

    @Test func aFileInsideLargerDataIsReadFromItsStart() throws {
        let bytes = try pack().encoded()
        let slice = (Data([1, 2, 3]) + bytes).dropFirst(3)
        #expect(try PackFile(data: slice) == pack())
    }

    @Test func aFileThatIsNotAPackIsRefused() {
        #expect(throws: PackFile.Failure.notAPack) { try PackFile(data: Data("hello, this is a text file".utf8)) }
        #expect(throws: PackFile.Failure.notAPack) { try PackFile(data: Data()) }
    }

    @Test func aFileThatIsTooLargeIsRefused() {
        #expect(throws: PackFile.Failure.tooLarge) {
            try PackFile(data: PackFile.magic + Data(count: PackFile.maximumBytes))
        }
    }

    @Test func aCutFileIsRefused() throws {
        let bytes = try pack().encoded()
        #expect(throws: PackFile.Failure.damaged) { try PackFile(data: bytes.dropLast(1)) }
        #expect(throws: PackFile.Failure.damaged) { try PackFile(data: bytes.prefix(PackFile.magic.count + 4)) }
    }

    @Test func aFileWithMoreBytesThanItsManifestNamesIsRefused() throws {
        #expect(throws: PackFile.Failure.damaged) { try PackFile(data: pack().encoded() + Data([0])) }
    }

    @Test func aManifestWithFalseSizesIsRefused() {
        let media = Data(count: 8)
        // A size larger than the file, a negative size, and a size that makes the sum pass the largest integer.
        for sizes in [[(1, 1), (1, 1), (1, 1), (1, 1000)], [(1, 1), (1, 1), (4, -2), (1, 1)], [(1, 1), (1, 1), (1, 1), (1, Int.max)]] {
            #expect(throws: PackFile.Failure.damaged) { try PackFile(data: file(manifest: manifest(sizes: sizes), media: media)) }
        }
    }

    @Test func aManifestThatIsNotJSONOrIsTooLongIsRefused() {
        #expect(throws: PackFile.Failure.damaged) { try PackFile(data: file(manifest: "not json", media: Data(count: 8))) }
        let long = manifest(sizes: Array(repeating: (1, 1), count: 4), name: String(repeating: "a", count: PackFile.maximumManifestBytes))
        #expect(throws: PackFile.Failure.damaged) { try PackFile(data: file(manifest: long, media: Data(count: 8))) }
    }

    @Test func aPackWithTheWrongNumberOfPosesIsRefused() {
        #expect(throws: PackFile.Failure.wrongPoseCount) {
            try PackFile(data: file(manifest: manifest(sizes: [(1, 1), (1, 1)]), media: Data(count: 4)))
        }
        #expect(throws: PackFile.Failure.wrongPoseCount) {
            try PackFile(data: file(manifest: manifest(sizes: Array(repeating: (1, 1), count: 5)), media: Data(count: 10)))
        }
    }

    @Test func aBadNameIsRefused() {
        let sizes = Array(repeating: (1, 1), count: 4)
        let media = Data(count: 8)
        for name in ["", "   ", String(repeating: "a", count: PackFile.maximumNameLength + 1), #"a\u0000b"#, #"line\nbreak"#] {
            #expect(throws: PackFile.Failure.badName) { try PackFile(data: file(manifest: manifest(sizes: sizes, name: name), media: media)) }
        }
        #expect(throws: PackFile.Failure.badName) { try pack(name: " ").encoded() }
    }
}
