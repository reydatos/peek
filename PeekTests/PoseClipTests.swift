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

    @Test func builtInPoseHasMoveOnlyWithStartPicture() {
        let catalog = PoseCatalog()
        for cue in catalog.packs.flatMap(\.cues) {
            #expect(cue.hasMove == (cue.startPicture != nil), "\(cue.id)")
        }
        // The classic pack has still pictures only.
        #expect(catalog.classicPack.cues.allSatisfy { !$0.hasMove })
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
}
