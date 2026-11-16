@testable import Peek
import Testing
import UIKit

@MainActor struct PoseLibraryTests {
    /// Each move of the Animations pack needs its start picture and its final picture.
    @Test func animationsPackHasTwoPicturesForEachMove() throws {
        let pack = try #require(PoseLibrary.packs.first { $0.id == "animations" })
        let moves = pack.cues.filter { $0.id != "director" }

        #expect(moves.count == 3)
        for cue in moves {
            #expect(cue.picture != nil, "\(cue.id) has no final picture")
            #expect(cue.startPicture != nil, "\(cue.id) has no start picture")
        }
    }

    @Test func theLibraryShowsThePacksInTheOrderOfTheirGroups() {
        let all = PoseCatalog().packs(for: .all)
        #expect(all.count == PoseLibrary.packs.count)
        #expect(all.first?.id == PoseLibrary.classicID)
        #expect(all.map(\.category) == all.map(\.category).sorted())
        // Inside a group, the packs keep the order of the list.
        #expect(all.filter { $0.category == .street }.map(\.id) == ["streetStyle", "hongKongHer", "hongKongHim"])
    }

    @Test func aFilterShowsOneGroup() {
        let kids = PoseCatalog().packs(for: .only(.kids))
        #expect(!kids.isEmpty)
        #expect(kids.allSatisfy { $0.category == .kids })
        #expect(PoseCatalog().packs(for: .only(.trends)).map(\.id) == ["asiaTrendsHer", "asiaTrendsHim"])
    }

    /// A customer pack with one pose. The files do not exist; the tests read no picture.
    func customerPack() -> PosePack {
        let still = URL(filePath: "/dev/null/still.jpg")
        return PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "The lean back", still: still),
        ])
    }

    @Test func aCustomerPackIsInTheCatalogAfterTheClassicPack() {
        let catalog = PoseCatalog(userPacks: [customerPack()])
        let all = catalog.packs(for: .all)
        #expect(all.count == PoseLibrary.packs.count + 1)
        #expect(all.map(\.id).prefix(2) == [PoseLibrary.classicID, "user-1"])
        #expect(catalog.packs(for: .only(.mine)).map(\.id) == ["user-1"])
        #expect(catalog.cue(for: "user-1-a") != nil)
        // A built-in pose has no clip and no files.
        #expect(catalog.cue(for: "smile")?.clipURL == nil)
    }

    @Test func aCustomerPackWithNoPoseIsNotInTheCatalog() {
        let catalog = PoseCatalog(userPacks: [PosePack(id: "empty", name: "Empty", cues: [])])
        #expect(catalog.pack(id: "empty") == nil)
        #expect(catalog.packs(for: .only(.mine)).isEmpty)
        // A booth that asks for it gets the classic booth, not a session with no slot.
        let model = BoothSessionModel(capture: FakeCapture(), packID: "empty", catalog: catalog, saver: FakeSaver())
        #expect(model.packID == PoseLibrary.classicID)
        model.loadPack("empty")
        #expect(model.state.slots.count == 4)
    }

    @Test func aBoothWithACustomerPackHasItsPoses() async {
        let catalog = PoseCatalog(userPacks: [customerPack()])
        let model = BoothSessionModel(capture: FakeCapture(), packID: "user-1", catalog: catalog, saver: FakeSaver())
        await model.startCamera()
        #expect(model.packID == "user-1")
        #expect(model.currentCue?.id == "user-1-a")
        // The accent of a customer pack is the strong color, so the label on it is the opposite color.
        #expect(model.onAccent == PeekTheme.onStrong)
    }

    @Test func aPackThatTheCatalogDoesNotHaveGivesTheClassicBooth() async {
        let model = BoothSessionModel(capture: FakeCapture(), packID: "removed-pack", saver: FakeSaver())
        await model.startCamera()
        #expect(model.packID == PoseLibrary.classicID)
        #expect(model.currentCue?.id == "smile")

        model.loadPack("removed-pack")
        #expect(model.packID == PoseLibrary.classicID)
        #expect(model.pack != nil)
    }
}
