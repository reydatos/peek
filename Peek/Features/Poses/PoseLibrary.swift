import SwiftUI

/// The packs that ship in the app. Cue names come from PRD FR-05 and from the UX lookbook (pages 04 and 04C).
/// No source names the cues of the Animations pack. The owner chose them on 2026-11-14.
///
/// The UI handoff gives three accents: cyan for Street Style, lime for Kids Poses, and pink for Animations.
/// The other accents are design values: cyan for city packs, lime for kids packs, pink for trend packs.
/// The classic booth has no accent color; its bar is the strong color, because only a primary action is red.
enum PoseLibrary {
    static let classicID = "classic"
    /// The one free built-in pack. The app opens on it, and it stands in for a pack that is gone.
    /// Its full-body photo poses give a match score in the first minute (owner decisions, 2026-11-24).
    static let freeID = "streetStyle"

    /// The last cue of each kids pack: the child calls the pose. Lookbook page 04.
    private static let director = PoseCue(id: "director", name: .cueDirector, symbol: "megaphone")

    /// The built-in packs. `PoseCatalog` adds the packs of the customer.
    static let packs: [PosePack] = [
        PosePack(id: classicID, name: .packClassic, subtitle: .packClassicSubtitle, accent: PeekTheme.strong, category: .classic, isPaid: true, cues: [
            PoseCue(id: "smile", name: .cueSmile, symbol: "face.smiling"),
            PoseCue(id: "lookAtEachOther", name: .cueLookAtEachOther, symbol: "person.2"),
            PoseCue(id: "silly", name: .cueSilly, symbol: "theatermasks"),
            PoseCue(id: "yourPick", name: .cueYourPick, symbol: "sparkles"),
        ]),
        PosePack(id: freeID, name: .packStreetStyle, subtitle: .packStreetStyleSubtitle, accent: PeekTheme.cyan, category: .street, isPaid: false, cues: [
            PoseCue(id: "walk", name: .cueWalk, symbol: "figure.walk"),
            PoseCue(id: "lookBack", name: .cueLookBack, symbol: "figure.stand"),
            PoseCue(id: "lean", name: .cueLean, symbol: "figure.cooldown"),
            PoseCue(id: "yourTake", name: .cueYourTake, symbol: "star"),
        ]),
        PosePack(id: "kidsPoses", name: .packKidsPoses, subtitle: .packKidsPosesSubtitle, accent: PeekTheme.lime, category: .kids, isPaid: true, cues: [
            PoseCue(id: "freezeRobot", name: .cueFreezeRobot, symbol: "figure.stand"),
            PoseCue(id: "reachStars", name: .cueReachStars, symbol: "star"),
            PoseCue(id: "flamingo", name: .cueFlamingo, symbol: "bird"),
            director,
        ]),
        PosePack(id: "creatureFeature", name: .packCreatureFeature, subtitle: .packCreatureFeatureSubtitle, accent: PeekTheme.lime, category: .kids, isPaid: true, cues: [
            PoseCue(id: "tinyTrex", name: .cueTinyTrex, symbol: "lizard"),
            PoseCue(id: "owlEyes", name: .cueOwlEyes, symbol: "binoculars"),
            PoseCue(id: "sleepySloth", name: .cueSleepySloth, symbol: "moon.zzz"),
            director,
        ]),
        PosePack(id: "cartoonCrew", name: .packCartoonCrew, subtitle: .packCartoonCrewSubtitle, accent: PeekTheme.lime, category: .kids, isPaid: true, cues: [
            PoseCue(id: "tooMuchPopcorn", name: .cueTooMuchPopcorn, symbol: "popcorn"),
            PoseCue(id: "youSawWhat", name: .cueYouSawWhat, symbol: "exclamationmark.bubble"),
            PoseCue(id: "slowMoSuperhero", name: .cueSlowMoSuperhero, symbol: "bolt"),
            director,
        ]),
        PosePack(id: "animations", name: .packAnimations, subtitle: .packAnimationsSubtitle, accent: PeekTheme.pink, category: .kids, isPaid: true, cues: [
            PoseCue(id: "squashAndStretch", name: .cueSquashAndStretch, symbol: "arrow.up.and.down"),
            PoseCue(id: "doubleTake", name: .cueDoubleTake, symbol: "eyes"),
            PoseCue(id: "jawDrop", name: .cueJawDrop, symbol: "mouth"),
            director,
        ]),
        PosePack(id: "grownUpsCopyMe", name: .packGrownUps, subtitle: .packGrownUpsSubtitle, accent: PeekTheme.lime, category: .kids, isPaid: true, cues: [
            PoseCue(id: "sameFace", name: .cueSameFace, symbol: "face.smiling"),
            PoseCue(id: "makeRoof", name: .cueMakeRoof, symbol: "house"),
            PoseCue(id: "seriousShowdown", name: .cueSeriousShowdown, symbol: "person.2"),
            director,
        ]),
        PosePack(id: "asiaTrendsHer", name: .packAsiaTrendsHer, subtitle: .packTrendsSubtitle, accent: PeekTheme.pink, category: .trends, isPaid: true, cues: [
            PoseCue(id: "doubleCheekHeart", name: .cueDoubleCheekHeart, symbol: "heart"),
            PoseCue(id: "gyaruPeace", name: .cueGyaruPeace, symbol: "hand.raised.fingers.spread"),
            PoseCue(id: "flowerCup", name: .cueFlowerCup, symbol: "camera.macro"),
            PoseCue(id: "catEars", name: .cueCatEars, symbol: "cat"),
        ]),
        PosePack(id: "asiaTrendsHim", name: .packAsiaTrendsHim, subtitle: .packTrendsSubtitle, accent: PeekTheme.pink, category: .trends, isPaid: true, cues: [
            PoseCue(id: "fingerHeart", name: .cueFingerHeart, symbol: "heart.circle"),
            PoseCue(id: "hairSweep", name: .cueHairSweep, symbol: "comb"),
            PoseCue(id: "jacketShoulder", name: .cueJacketShoulder, symbol: "jacket"),
            PoseCue(id: "neckHold", name: .cueNeckHold, symbol: "figure.stand"),
        ]),
        PosePack(id: "hongKongHer", name: .packHongKongHer, subtitle: .packCitySubtitle, accent: PeekTheme.cyan, category: .street, isPaid: true, cues: [
            PoseCue(id: "hkStepPause", name: .cueStepPause, symbol: "figure.stairs"),
            PoseCue(id: "hkBagSwing", name: .cueBagSwing, symbol: "bag"),
            PoseCue(id: "hkShutterLean", name: .cueShutterLean, symbol: "figure.stand"),
            PoseCue(id: "hkShadesPeek", name: .cueShadesPeek, symbol: "sunglasses"),
        ]),
        PosePack(id: "hongKongHim", name: .packHongKongHim, subtitle: .packCitySubtitle, accent: PeekTheme.cyan, category: .street, isPaid: true, cues: [
            PoseCue(id: "hkStairSit", name: .cueStairSit, symbol: "figure.stairs"),
            PoseCue(id: "hkLookAway", name: .cueLookAway, symbol: "figure.stand"),
            PoseCue(id: "hkCapTug", name: .cueCapTug, symbol: "hat.cap"),
            PoseCue(id: "hkBagWalk", name: .cueBagWalk, symbol: "figure.walk"),
        ]),
    ]

    /// A built-in pose by its ID.
    static func cue(for id: String) -> PoseCue? {
        packs.lazy.flatMap(\.cues).first { $0.id == id }
    }
}
