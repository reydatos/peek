import Foundation

/// The one table of store products (eng review, finding #9). App Store Connect and `Config/Products.storekit`
/// must list the same IDs; a test checks the file. An ID is permanent once App Store Connect has it.
///
/// Prices (owner decisions, 2026-11-24): $1.99 for each pack, All Packs $19.99 a year with no trial.
/// The prices live in App Store Connect and in the configuration file, not in code.
enum StoreProducts {
    /// The yearly subscription that unlocks every paid pack, the packs of later updates too.
    static let allPacks = "com.a8media.peek.allpacks.yearly"

    /// The fixed themed bundles: one product that unlocks some packs. The owner has not named them yet,
    /// so the table is empty. A bundle adds one line here: its product ID and the IDs of its packs.
    static let bundles: [String: Set<String>] = [:]

    /// The terms and the privacy policy, linked from the subscription offer (App Review guideline 3.1.2).
    /// The terms are the standard Apple license. The privacy page must be live before the app goes to review.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://peek.therevolv.com/privacy")!

    /// The product of a paid built-in pack.
    static func pack(_ packID: String) -> String {
        "com.a8media.peek.pack.\(packID)"
    }

    /// Every product that the app sells.
    static var all: [String] {
        PoseLibrary.packs.compactMap(\.productID) + bundles.keys.sorted() + [allPacks]
    }

    /// True when the products unlock the pack. A free pack is always unlocked.
    static func unlocks(_ pack: PosePack, owned: Set<String>) -> Bool {
        guard let productID = pack.productID else { return true }
        if owned.contains(allPacks) || owned.contains(productID) {
            return true
        }
        return bundles.contains { owned.contains($0.key) && $0.value.contains(pack.id) }
    }
}
