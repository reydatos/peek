@testable import Peek
import StoreKit
import SwiftUI

/// A store with no App Store. Each test sets the answer of each call.
final class FakeStoreClient: StoreClient {
    var itemsError: (any Error)?
    /// Products that the App Store does not return, as products not set up in App Store Connect.
    var missing: Set<String> = []
    var purchaseResult: Result<PurchaseOutcome, any Error> = .success(.purchased)
    var owned: Set<String> = []
    var syncError: (any Error)?
    /// The products that Restore Purchases finds.
    var syncFinds: Set<String> = []
    private(set) var purchases: [String] = []
    private(set) var syncCount = 0
    private var continuation: AsyncStream<Void>.Continuation?

    func items(for ids: [String]) async throws -> [StoreItem] {
        if let itemsError {
            throw itemsError
        }
        return ids.filter { !missing.contains($0) }.map { StoreItem(id: $0, displayPrice: "$19.99") }
    }

    func purchase(_ id: String, with _: PurchaseAction?) async throws -> PurchaseOutcome {
        purchases.append(id)
        let outcome = try purchaseResult.get()
        if outcome == .purchased {
            owned.insert(id)
        }
        return outcome
    }

    func ownedProducts() async -> Set<String> {
        owned
    }

    func sync() async throws {
        syncCount += 1
        if let syncError {
            throw syncError
        }
        owned.formUnion(syncFinds)
    }

    func transactionUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation = $0 }
    }

    /// A transaction from outside the app: an Ask to Buy approval, a renewal, or a refund.
    func sendUpdate(owned: Set<String>) {
        self.owned = owned
        continuation?.yield()
    }
}

struct FakeStoreError: Error {}

/// Waits until the condition is true, for at most 2 seconds.
func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0 ..< 200 {
        if condition() {
            return true
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}
