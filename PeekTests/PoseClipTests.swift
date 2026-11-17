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
}
