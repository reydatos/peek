import Observation
import StoreKit
import SwiftUI

/// The state of the unlock sheet for one pack: the purchase, Restore Purchases, and their messages (5A).
@Observable
final class UnlockFlow {
    enum Phase: Equatable {
        case idle
        case buying(String)
        case restoring
        /// The pack is unlocked. The sheet shows a check, then closes and selects the pack.
        case succeeded
    }

    enum Notice: Equatable {
        case purchaseFailed
        case restored
        case nothingToRestore
        case restoreFailed
    }

    let pack: PosePack
    let entitlements: Entitlements
    private(set) var phase = Phase.idle
    private(set) var notice: Notice?
    /// The product of the last purchase, for Try again.
    private(set) var lastProductID: String?

    init(pack: PosePack, entitlements: Entitlements) {
        self.pack = pack
        self.entitlements = entitlements
    }

    var isUnlocked: Bool {
        entitlements.isUnlocked(pack)
    }

    var isBusy: Bool {
        phase != .idle
    }

    /// True while an Ask to Buy purchase of the product waits for a parent.
    func isWaiting(_ productID: String) -> Bool {
        entitlements.waiting.contains(productID)
    }

    func buy(_ productID: String, with action: PurchaseAction? = nil) async {
        notice = nil
        lastProductID = productID
        phase = .buying(productID)
        do {
            let outcome = try await entitlements.purchase(productID, with: action)
            // A cancelled purchase changes nothing, and the sheet stays open.
            phase = outcome == .purchased && isUnlocked ? .succeeded : .idle
        } catch {
            phase = .idle
            notice = .purchaseFailed
        }
    }

    func restore() async {
        notice = nil
        phase = .restoring
        do {
            switch try await entitlements.restore() {
            case .restored: notice = .restored
            case .nothingFound: notice = .nothingToRestore
            case .cancelled: break
            }
        } catch {
            notice = .restoreFailed
        }
        phase = isUnlocked ? .succeeded : .idle
    }

    /// The pack became unlocked outside a purchase of this sheet: an Ask to Buy approval, or another device.
    func noteUnlock() {
        if isUnlocked, phase == .idle {
            phase = .succeeded
        }
    }
}
