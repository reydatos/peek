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

    @Test func theLibraryShowsThePacksInTheOrderOfTheirGroups() {
        let all = PoseLibrary.packs(for: .all)
        #expect(all.count == PoseLibrary.packs.count)
        #expect(all.first?.id == PoseLibrary.classicID)
        #expect(all.map(\.category) == all.map(\.category).sorted())
        // Inside a group, the packs keep the order of the list.
        #expect(all.filter { $0.category == .street }.map(\.id) == ["streetStyle", "hongKongHer", "hongKongHim"])
    }

    @Test func aFilterShowsOneGroup() {
        let kids = PoseLibrary.packs(for: .only(.kids))
        #expect(!kids.isEmpty)
        #expect(kids.allSatisfy { $0.category == .kids })
        #expect(PoseLibrary.packs(for: .only(.trends)).map(\.id) == ["asiaTrendsHer", "asiaTrendsHim"])
    }
}
