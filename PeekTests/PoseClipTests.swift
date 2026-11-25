import AVFoundation
import Foundation
@testable import Peek
import Testing

@MainActor
struct PoseClipTests {
    private let still = URL(filePath: "/nowhere/still.jpg")

    @Test func customerPoseWithClipHasMove() {
        let cue = PoseCue(id: "user-a", name: "Jump", still: still, clip: URL(filePath: "/nowhere/clip.mov"))
        #expect(cue.hasMove)
    }

    @Test func customerPoseWithNoClipHasNoMove() {
        #expect(!PoseCue(id: "user-a", name: "Jump", still: still).hasMove)
    }

    @Test func builtInPoseHasMoveOnlyWithStartPicture() throws {
        let catalog = PoseCatalog()
        for cue in catalog.packs.flatMap(\.cues) {
            #expect(cue.hasMove == (cue.startPicture != nil), "\(cue.id)")
        }
        // The classic pack has still pictures only.
        #expect(try #require(catalog.pack(id: PoseLibrary.classicID)?.cues.allSatisfy { !$0.hasMove }))
    }

    @Test func clipLoopIsSilentAndDoesNotKeepTheDisplayOn() {
        let loop = ClipLoop(url: URL(filePath: "/nowhere/clip.mov"))
        #expect(loop.player.isMuted)
        #expect(!loop.player.preventsDisplaySleepDuringVideoPlayback)
    }

    @Test func aCancelThenAStartAtOnceGivesOneGoodRecording() async {
        let capture = FakeCapture()
        let recording = PoseRecording(capture: capture, sleep: { _ in
            try Task.checkCancellation()
            await Task.yield()
        })
        recording.start()
        let old = recording.task
        recording.cancel()
        recording.start()
        // The old task ends after the cancel. It must not change the state of the new recording.
        await old?.value
        await recording.task?.value
        #expect(recording.phase == .done)
        #expect(recording.clipURL != nil)
        #expect(await capture.clipCount == 1)
    }

    @Test func aPackNameOfControlCharactersOnlyIsNotComplete() {
        let draft = PackDraft()
        for index in draft.poses.indices {
            draft.poses[index].still = FakeCapture.photoData
            draft.poses[index].clipURL = URL(filePath: "/nowhere/\(index).mov")
        }
        draft.name = "\u{0}\u{1}"
        #expect(!draft.isComplete)
        draft.name = "Friday"
        #expect(draft.isComplete)
    }

    @Test func theAppRemovesOldClipsAndPackFilesWhenItOpens() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let share = folder.appending(path: "Share-1")
        try FileManager.default.createDirectory(at: share, withIntermediateDirectories: true)
        let clip = folder.appending(path: "a.mov")
        let pack = share.appending(path: "Beach.peekpack")
        let other = folder.appending(path: "notes.txt")
        for file in [clip, pack, other] {
            try Data("x".utf8).write(to: file)
        }
        StaleClips.remove(in: folder)
        #expect(!FileManager.default.fileExists(atPath: clip.path))
        #expect(!FileManager.default.fileExists(atPath: share.path))
        // A file of a different kind stays.
        #expect(FileManager.default.fileExists(atPath: other.path))
    }

    /// A booth at "ready" with a customer pack. The first pose has a clip, or not.
    private func booth(hasClip: Bool) async -> BoothSessionModel {
        let clip = hasClip ? URL(filePath: "/nowhere/clip.mov") : nil
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: clip),
            PoseCue(id: "user-1-b", name: "Two", still: still, clip: clip),
        ])])
        let model = BoothSessionModel(capture: FakeCapture(), packID: "user-1", catalog: catalog, saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        return model
    }

    @Test func aTapOnThePosePictureOpensTheLargeClipAndASecondTapClosesIt() async {
        let model = await booth(hasClip: true)
        #expect(model.canPlayClip)
        #expect(model.shownClipLook == .corner)
        model.togglePoseClip()
        #expect(model.shownClipLook == .large)
        model.togglePoseClip()
        #expect(model.shownClipLook == .corner)
    }

    @Test func aPoseWithNoClipHasNoClipOverThePicture() async {
        let model = await booth(hasClip: false)
        #expect(!model.canPlayClip)
        model.togglePoseClip()
        model.setClipLook(.ghost)
        #expect(model.shownClipLook == .corner)
    }

    @Test func theLargeClipClosesWhenTheShotStarts() async {
        let model = await booth(hasClip: true)
        model.togglePoseClip()
        model.send(.start)
        #expect(model.state.phase != .ready)
        #expect(model.clipLook == .corner)
    }

    @Test func theGhostHidesDuringTheShotAndStaysOnForTheNextPose() async {
        let model = await booth(hasClip: true)
        model.setClipLook(.ghost)
        #expect(model.shownClipLook == .ghost)
        model.send(.start)
        // Out of live framing the ghost does not show, so it is not in the way of the countdown.
        #expect(model.shownClipLook == .corner)
        #expect(model.clipLook == .ghost)
        // A tap on the pose picture closes the ghost.
        model.send(.cancel)
        #expect(model.shownClipLook == .ghost)
        model.togglePoseClip()
        #expect(model.shownClipLook == .corner)
    }

    @Test func theGhostShowsTheLivePictureOnTheOuterDisplay() async {
        let model = await booth(hasClip: true)
        model.setOuterDisplayAvailable(true)
        #expect(model.isOuterDisplayPresenting)
        model.send(.showSubject(.reference))
        model.setClipLook(.ghost)
        // The people in the photo see the ghost over the live picture, not the pose reference.
        #expect(model.state.subjectView == .live)
    }
}
