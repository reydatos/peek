import Observation
import StoreKit
import SwiftUI

/// The one store of what the customer owns. Callers ask `isUnlocked(_:)`; StoreKit stays behind `StoreClient`.
///
/// The app reads it when a pack is chosen and when a New set starts (D5). An open set or a restored draft keeps
/// its pack until the set ends, so an expiry or a refund never stops a set in progress.
@Observable
final class Entitlements {
    enum Prices: Equatable {
        case loading
        case failed
        case loaded([String: String])
    }

    enum RestoreOutcome: Equatable {
        case restored
        case nothingFound
        /// The customer closed the sign-in. Nothing shows.
        case cancelled
    }

    /// The products that the customer owns.
    private(set) var owned: Set<String> = []
    /// False until the first read of the owned products ends. Until then, no card shows a lock or a check.
    private(set) var isLoaded = false
    /// Ask to Buy purchases that wait for a parent. An approval removes the product from this set.
    private(set) var waiting: Set<String> = []
    private(set) var prices = Prices.loading
    private let client: any StoreClient
    private var listener: Task<Void, Never>?

    init(client: any StoreClient) {
        self.client = client
    }

    /// Starts the transaction listener, then reads the owned products. The app calls this at launch, so an
    /// Ask to Buy approval or a renewal that came while the app was closed arrives at once.
    func start() async {
        if listener == nil {
            let updates = client.transactionUpdates()
            listener = Task { [weak self] in
                for await _ in updates {
                    await self?.refresh()
                }
            }
        }
        await refresh()
    }

    /// Reads the owned products again. The app calls it when it becomes active, so an expiry is seen.
    func refresh() async {
        owned = await client.ownedProducts()
        waiting = waiting.filter { !owned.contains($0) }
        isLoaded = true
    }

    /// True when the customer can use the pack. A paid pack counts as locked until the first read ends.
    func isUnlocked(_ pack: PosePack) -> Bool {
        guard pack.productID != nil else { return true }
        return isLoaded && StoreProducts.unlocks(pack, owned: owned)
    }

    var hasAllPacks: Bool {
        owned.contains(StoreProducts.allPacks)
    }

    /// Loads the prices of every product.
    func loadPrices() async {
        prices = .loading
        do {
            let items = try await client.items(for: StoreProducts.all)
            prices = items.isEmpty ? .failed : .loaded(Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.displayPrice) }))
        } catch {
            prices = .failed
        }
    }

    /// True when the prices loaded but the App Store did not return this product, as a product that is not
    /// set up in App Store Connect yet. The sheet then shows the failed state, not a spinner that never stops.
    func isMissing(_ productID: String) -> Bool {
        if case let .loaded(prices) = prices {
            return prices[productID] == nil
        }
        return false
    }

    func price(of productID: String) -> String? {
        if case let .loaded(prices) = prices {
            return prices[productID]
        }
        return nil
    }

    /// Buys a product. A failed purchase throws.
    func purchase(_ productID: String, with action: PurchaseAction? = nil) async throws -> PurchaseOutcome {
        let outcome = try await client.purchase(productID, with: action)
        switch outcome {
        case .purchased:
            await refresh()
        case .pending:
            waiting.insert(productID)
        case .cancelled:
            break
        }
        return outcome
    }

    /// Restore Purchases. A failed sync other than a closed sign-in throws.
    func restore() async throws -> RestoreOutcome {
        do {
            try await client.sync()
        } catch StoreKitError.userCancelled {
            return .cancelled
        }
        await refresh()
        return owned.isEmpty ? .nothingFound : .restored
    }
}
