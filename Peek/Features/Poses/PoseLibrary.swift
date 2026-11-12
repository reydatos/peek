import SwiftUI

/// The packs that ship in the app. Cue names come from PRD FR-05.
/// The Animations pack is not here: the PRD does not name its cues.
enum PoseLibrary {
    static let classicID = "classic"

    static let packs: [PosePack] = [
        PosePack(id: classicID, name: .packClassic, isFree: true, cues: [
            PoseCue(id: "smile", name: .cueSmile, symbol: "face.smiling"),
            PoseCue(id: "lookAtEachOther", name: .cueLookAtEachOther, symbol: "person.2"),
            PoseCue(id: "silly", name: .cueSilly, symbol: "theatermasks"),
            PoseCue(id: "yourPick", name: .cueYourPick, symbol: "sparkles"),
        ]),
        PosePack(id: "streetStyle", name: .packStreetStyle, isFree: false, cues: [
            PoseCue(id: "walk", name: .cueWalk, symbol: "figure.walk"),
            PoseCue(id: "lookBack", name: .cueLookBack, symbol: "figure.stand"),
            PoseCue(id: "lean", name: .cueLean, symbol: "figure.cooldown"),
            PoseCue(id: "yourTake", name: .cueYourTake, symbol: "star"),
        ]),
        PosePack(id: "kidsPoses", name: .packKidsPoses, isFree: false, cues: [
            PoseCue(id: "copyMe", name: .cueCopyMe, symbol: "figure.2"),
            PoseCue(id: "freeze", name: .cueFreeze, symbol: "snowflake"),
            PoseCue(id: "swapFaces", name: .cueSwapFaces, symbol: "arrow.left.arrow.right"),
            PoseCue(id: "director", name: .cueDirector, symbol: "megaphone"),
        ]),
        PosePack(id: "asiaTrendsHer", name: .packAsiaTrendsHer, isFree: false, cues: [
            PoseCue(id: "doubleCheekHeart", name: .cueDoubleCheekHeart, symbol: "heart"),
            PoseCue(id: "gyaruPeace", name: .cueGyaruPeace, symbol: "hand.raised.fingers.spread"),
            PoseCue(id: "flowerCup", name: .cueFlowerCup, symbol: "camera.macro"),
            PoseCue(id: "catEars", name: .cueCatEars, symbol: "cat"),
        ]),
        PosePack(id: "asiaTrendsHim", name: .packAsiaTrendsHim, isFree: false, cues: [
            PoseCue(id: "fingerHeart", name: .cueFingerHeart, symbol: "heart.circle"),
            PoseCue(id: "hairSweep", name: .cueHairSweep, symbol: "comb"),
            PoseCue(id: "jacketShoulder", name: .cueJacketShoulder, symbol: "jacket"),
            PoseCue(id: "neckHold", name: .cueNeckHold, symbol: "figure.stand"),
        ]),
        PosePack(id: "hongKongHer", name: .packHongKongHer, isFree: false, cues: [
            PoseCue(id: "hkStepPause", name: .cueStepPause, symbol: "figure.stairs"),
            PoseCue(id: "hkBagSwing", name: .cueBagSwing, symbol: "bag"),
            PoseCue(id: "hkShutterLean", name: .cueShutterLean, symbol: "figure.stand"),
            PoseCue(id: "hkShadesPeek", name: .cueShadesPeek, symbol: "sunglasses"),
        ]),
        PosePack(id: "hongKongHim", name: .packHongKongHim, isFree: false, cues: [
            PoseCue(id: "hkStairSit", name: .cueStairSit, symbol: "figure.stairs"),
            PoseCue(id: "hkLookAway", name: .cueLookAway, symbol: "figure.stand"),
            PoseCue(id: "hkCapTug", name: .cueCapTug, symbol: "hat.cap"),
            PoseCue(id: "hkBagWalk", name: .cueBagWalk, symbol: "figure.walk"),
        ]),
    ]

    static func cueIDs(forPack id: String) -> [String] {
        (packs.first { $0.id == id } ?? packs[0]).cues.map(\.id)
    }

    static func cue(for id: String) -> PoseCue? {
        packs.lazy.flatMap(\.cues).first { $0.id == id }
    }
}
