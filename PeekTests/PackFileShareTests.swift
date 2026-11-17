import Foundation
@testable import Peek
import PeekCore
import Testing
import UIKit

@MainActor struct PackFileShareTests {
    let store = FilePackStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    private func draft() throws -> PackDraft {
        let draft = PackDraft()
        draft.name = "Beach / day"
        for index in draft.poses.indices {
            let clip = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
            try Data("clip \(index)".utf8).write(to: clip)
            draft.setRecording(still: FakeCapture.photoData, clipURL: clip, at: index)
            draft.poses[index].name = "Move \(index)"
        }
        return draft
    }

    /// The tests use made-up media, so the examination of the media is off here. It has its own tests.
    private func packs(checkMedia: @escaping @Sendable (PackFile) async -> Bool = { _ in true }) -> UserPacks {
        UserPacks(catalog: PoseCatalog(), store: store, checkMedia: checkMedia)
    }

    @Test func anExportedPackComesBackAsANewPackWithTheSameContent() async throws {
        let packs = packs()
        let id = try #require(try await packs.save(draft()))
        let url = try #require(await packs.exportFile(packID: id))
        // The file name has the pack name, with no path divider from it.
        #expect(url.lastPathComponent == "Beach - day.peekpack")

        let file = try #require(await packs.readPackFile(at: url))
        #expect(file.name == "Beach / day")
        #expect(file.poses.map(\.name) == ["Move 0", "Move 1", "Move 2", "Move 3"])
        #expect(file.poses.map(\.clip) == (0 ..< 4).map { Data("clip \($0)".utf8) })

        let newID = try #require(await packs.add(file))
        // The app makes new IDs. The pack from the file is a second pack.
        #expect(newID != id)
        #expect(packs.catalog.userPacks.count == 2)
        let pack = try #require(packs.catalog.pack(id: newID))
        #expect(pack.cues.allSatisfy { $0.id.hasPrefix(UserPacks.idPrefix) && $0.clipURL != nil && $0.picture != nil })
    }

    @Test func aBuiltInPackHasNoPackFile() async {
        #expect(await packs().exportFile(packID: PoseLibrary.classicID) == nil)
    }

    @Test func aFileThatIsNotAPackIsRefused() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).peekpack")
        try Data("not a pack".utf8).write(to: url)
        #expect(await packs().readPackFile(at: url) == nil)
        #expect(await packs().readPackFile(at: URL(filePath: "/nowhere/a.peekpack")) == nil)
    }

    @Test func aPackWithMediaThatTheAppDoesNotAcceptIsRefused() async throws {
        let writer = packs()
        let id = try #require(try await writer.save(draft()))
        let url = try #require(await writer.exportFile(packID: id))
        // The real examination: the made-up clip is not a video.
        let reader = UserPacks(catalog: PoseCatalog(), store: store)
        #expect(await reader.readPackFile(at: url) == nil)
    }

    @Test func theImportAsksBeforeItAddsThePack() async throws {
        let packs = packs()
        let id = try #require(try await packs.save(draft()))
        let url = try #require(await packs.exportFile(packID: id))
        let packImport = PackImport(userPacks: packs)

        await packImport.open(url)
        #expect(packImport.pending?.name == "Beach / day")
        #expect(packs.catalog.userPacks.count == 1)
        packImport.cancel()
        #expect(packImport.pending == nil)
        #expect(packs.catalog.userPacks.count == 1)

        await packImport.open(url)
        await packImport.confirm()
        #expect(packs.catalog.userPacks.count == 2)
        #expect(!packImport.isFailed)

        await packImport.open(URL(filePath: "/nowhere/a.peekpack"))
        #expect(packImport.isFailed)
        #expect(packImport.pending == nil)
    }

    @Test func aPictureMustBeOneJPEGOfASensibleSize() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 40)).image { context in
            context.fill(CGRect(x: 0, y: 0, width: 30, height: 40))
        }
        let jpeg = try #require(image.jpegData(compressionQuality: 0.8))
        #expect(PackMediaCheck.isPicture(jpeg))
        // A PNG, text, and no bytes are not accepted.
        #expect(!PackMediaCheck.isPicture(FakeCapture.photoData))
        #expect(!PackMediaCheck.isPicture(Data("<svg/>".utf8)))
        #expect(!PackMediaCheck.isPicture(Data()))
    }

    @Test func aClipMustBeAVideo() async {
        #expect(await !PackMediaCheck.isClip(Data("clip".utf8)))
        #expect(await !PackMediaCheck.isClip(FakeCapture.photoData))
    }

    @Test func aPackWithAVeryLongNameStillGoesIntoAFile() async throws {
        let packs = packs()
        let draft = try draft()
        draft.name = String(repeating: "long name ", count: 20)
        draft.poses[0].name = String(repeating: "x", count: 200)
        let id = try #require(await packs.save(draft))
        let url = try #require(await packs.exportFile(packID: id))
        let file = try #require(await packs.readPackFile(at: url))
        #expect(file.name.count <= PackFile.maximumNameLength)
        #expect(file.poses[0].name.count == PackFile.maximumNameLength)
    }
}
