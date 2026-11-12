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
            PoseCue(id: "cheekHeart", name: .cueCheekHeart, symbol: "heart"),
            PoseCue(id: "peaceEye", name: .cuePeaceEye, symbol: "hand.raised.fingers.spread"),
            PoseCue(id: "sitLow", name: .cueSitLow, symbol: "figure.mind.and.body"),
            PoseCue(id: "hairTuck", name: .cueHairTuck, symbol: "person.crop.circle"),
        ]),
        PosePack(id: "asiaTrendsHim", name: .packAsiaTrendsHim, isFree: false, cues: [
            PoseCue(id: "fingerHeart", name: .cueFingerHeart, symbol: "heart.circle"),
            PoseCue(id: "fixCollar", name: .cueFixCollar, symbol: "tshirt"),
            PoseCue(id: "lowSquat", name: .cueLowSquat, symbol: "figure.strengthtraining.functional"),
            PoseCue(id: "lookDown", name: .cueLookDown, symbol: "figure.walk.motion"),
        ]),
    ]

    static func cueIDs(forPack id: String) -> [String] {
        (packs.first { $0.id == id } ?? packs[0]).cues.map(\.id)
    }

    static func cue(for id: String) -> PoseCue? {
        packs.lazy.flatMap(\.cues).first { $0.id == id }
    }
}
