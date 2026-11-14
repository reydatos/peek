import SwiftUI

/// The packs that ship in the app. Cue names come from PRD FR-05 and from the UX lookbook (pages 04 and 04C).
/// The Animations pack is not here: no source names its cues.
///
/// The lookbook gives a tile color for Street Style and Kids Poses. The other tile colors are design values:
/// cyan for editorial packs, lime for kids packs, pink for trend packs.
enum PoseLibrary {
    static let classicID = "classic"

    /// The last cue of each kids pack: the child calls the pose. Lookbook page 04.
    private static let director = PoseCue(id: "director", name: .cueDirector, symbol: "megaphone")

    static let packs: [PosePack] = [
        PosePack(id: classicID, name: .packClassic, subtitle: .packClassicSubtitle, accent: PeekTheme.accent, isFree: true, cues: [
            PoseCue(id: "smile", name: .cueSmile, symbol: "face.smiling"),
            PoseCue(id: "lookAtEachOther", name: .cueLookAtEachOther, symbol: "person.2"),
            PoseCue(id: "silly", name: .cueSilly, symbol: "theatermasks"),
            PoseCue(id: "yourPick", name: .cueYourPick, symbol: "sparkles"),
        ]),
        PosePack(id: "streetStyle", name: .packStreetStyle, subtitle: .packStreetStyleSubtitle, accent: PeekTheme.live, isFree: false, cues: [
            PoseCue(id: "walk", name: .cueWalk, symbol: "figure.walk"),
            PoseCue(id: "lookBack", name: .cueLookBack, symbol: "figure.stand"),
            PoseCue(id: "lean", name: .cueLean, symbol: "figure.cooldown"),
            PoseCue(id: "yourTake", name: .cueYourTake, symbol: "star"),
        ]),
        PosePack(id: "kidsPoses", name: .packKidsPoses, subtitle: .packKidsPosesSubtitle, accent: PeekTheme.lime, isFree: false, cues: [
            PoseCue(id: "freezeRobot", name: .cueFreezeRobot, symbol: "figure.stand"),
            PoseCue(id: "reachStars", name: .cueReachStars, symbol: "star"),
            PoseCue(id: "flamingo", name: .cueFlamingo, symbol: "bird"),
            director,
        ]),
        PosePack(id: "creatureFeature", name: .packCreatureFeature, subtitle: .packCreatureFeatureSubtitle, accent: PeekTheme.lime, isFree: false, cues: [
            PoseCue(id: "tinyTrex", name: .cueTinyTrex, symbol: "lizard"),
            PoseCue(id: "owlEyes", name: .cueOwlEyes, symbol: "binoculars"),
            PoseCue(id: "sleepySloth", name: .cueSleepySloth, symbol: "moon.zzz"),
            director,
        ]),
        PosePack(id: "cartoonCrew", name: .packCartoonCrew, subtitle: .packCartoonCrewSubtitle, accent: PeekTheme.lime, isFree: false, cues: [
            PoseCue(id: "tooMuchPopcorn", name: .cueTooMuchPopcorn, symbol: "popcorn"),
            PoseCue(id: "youSawWhat", name: .cueYouSawWhat, symbol: "exclamationmark.bubble"),
            PoseCue(id: "slowMoSuperhero", name: .cueSlowMoSuperhero, symbol: "bolt"),
            director,
        ]),
        PosePack(id: "grownUpsCopyMe", name: .packGrownUps, subtitle: .packGrownUpsSubtitle, accent: PeekTheme.lime, isFree: false, cues: [
            PoseCue(id: "sameFace", name: .cueSameFace, symbol: "face.smiling"),
            PoseCue(id: "makeRoof", name: .cueMakeRoof, symbol: "house"),
            PoseCue(id: "seriousShowdown", name: .cueSeriousShowdown, symbol: "person.2"),
            director,
        ]),
        PosePack(id: "asiaTrendsHer", name: .packAsiaTrendsHer, subtitle: .packTrendsSubtitle, accent: PeekTheme.pink, isFree: false, cues: [
            PoseCue(id: "doubleCheekHeart", name: .cueDoubleCheekHeart, symbol: "heart"),
            PoseCue(id: "gyaruPeace", name: .cueGyaruPeace, symbol: "hand.raised.fingers.spread"),
            PoseCue(id: "flowerCup", name: .cueFlowerCup, symbol: "camera.macro"),
            PoseCue(id: "catEars", name: .cueCatEars, symbol: "cat"),
        ]),
        PosePack(id: "asiaTrendsHim", name: .packAsiaTrendsHim, subtitle: .packTrendsSubtitle, accent: PeekTheme.pink, isFree: false, cues: [
            PoseCue(id: "fingerHeart", name: .cueFingerHeart, symbol: "heart.circle"),
            PoseCue(id: "hairSweep", name: .cueHairSweep, symbol: "comb"),
            PoseCue(id: "jacketShoulder", name: .cueJacketShoulder, symbol: "jacket"),
            PoseCue(id: "neckHold", name: .cueNeckHold, symbol: "figure.stand"),
        ]),
        PosePack(id: "hongKongHer", name: .packHongKongHer, subtitle: .packCitySubtitle, accent: PeekTheme.live, isFree: false, cues: [
            PoseCue(id: "hkStepPause", name: .cueStepPause, symbol: "figure.stairs"),
            PoseCue(id: "hkBagSwing", name: .cueBagSwing, symbol: "bag"),
            PoseCue(id: "hkShutterLean", name: .cueShutterLean, symbol: "figure.stand"),
            PoseCue(id: "hkShadesPeek", name: .cueShadesPeek, symbol: "sunglasses"),
        ]),
        PosePack(id: "hongKongHim", name: .packHongKongHim, subtitle: .packCitySubtitle, accent: PeekTheme.live, isFree: false, cues: [
            PoseCue(id: "hkStairSit", name: .cueStairSit, symbol: "figure.stairs"),
            PoseCue(id: "hkLookAway", name: .cueLookAway, symbol: "figure.stand"),
            PoseCue(id: "hkCapTug", name: .cueCapTug, symbol: "hat.cap"),
            PoseCue(id: "hkBagWalk", name: .cueBagWalk, symbol: "figure.walk"),
        ]),
    ]

    /// The Copycat packs: every pack but the classic booth.
    static var copycatPacks: [PosePack] {
        packs.filter { $0.id != classicID }
    }

    static func cueIDs(forPack id: String) -> [String] {
        (packs.first { $0.id == id } ?? packs[0]).cues.map(\.id)
    }

    static func cue(for id: String) -> PoseCue? {
        packs.lazy.flatMap(\.cues).first { $0.id == id }
    }
}
