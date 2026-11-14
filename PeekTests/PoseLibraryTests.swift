@testable import Peek
import Testing
import UIKit

struct PoseLibraryTests {
    /// Each move of the Animations pack needs its start picture and its final picture.
    @Test func animationsPackHasTwoPicturesForEachMove() throws {
        let pack = try #require(PoseLibrary.packs.first { $0.id == "animations" })
        let moves = pack.cues.filter { $0.id != "director" }

        #expect(moves.count == 3)
        for cue in moves {
            #expect(UIImage(named: cue.assetName) != nil, "\(cue.id) has no final picture")
            #expect(UIImage(named: cue.startAssetName) != nil, "\(cue.id) has no start picture")
        }
    }
}
