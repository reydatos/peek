import Foundation

/// The one table of store products (eng review, finding #9). App Store Connect and `Config/Products.storekit`
/// must list the same IDs; a test checks the file. An ID is permanent once App Store Connect has it.
///
/// The app sells one product (owner decision, 2026-11-24): All Packs, $19.99 a year with no trial. It unlocks
/// every paid pack. The price lives in App Store Connect and in the configuration file, not in code.
enum StoreProducts {
    /// The yearly subscription that unlocks every paid pack, the packs of later updates too.
    static let allPacks = "com.a8media.peek.allpacks.yearly"

    /// The terms and the privacy policy, linked from the subscription offer (App Review guideline 3.1.2).
    /// The terms are the standard Apple license. The privacy page must be live before the app goes to review.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://peek.therevolv.com/privacy")!

    /// Every product that the app sells.
    static let all = [allPacks]

    /// True when the products unlock the pack. A free pack is always unlocked.
    static func unlocks(_ pack: PosePack, owned: Set<String>) -> Bool {
        !pack.isPaid || owned.contains(allPacks)
    }
}
