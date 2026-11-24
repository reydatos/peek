import StoreKit
import SwiftUI

/// A product with its price in the currency of the customer's storefront.
struct StoreItem: Equatable {
    let id: String
    let displayPrice: String
}

/// How a purchase ended. An error is thrown for a failed purchase.
enum PurchaseOutcome: Equatable {
    case purchased
    /// Ask to Buy: a parent must approve. An approval arrives later through the transaction updates.
    case pending
    case cancelled
}

/// The seam between the app and StoreKit. `AppStoreClient` talks to the App Store; the tests use a fake.
protocol StoreClient {
    func items(for ids: [String]) async throws -> [StoreItem]
    /// Buys a product. SwiftUI passes its purchase action, so the confirmation shows over the right scene.
    func purchase(_ id: String, with action: PurchaseAction?) async throws -> PurchaseOutcome
    /// The products that the customer owns now: verified and not refunded. StoreKit leaves out an expired
    /// subscription and keeps one in its billing grace period.
    func ownedProducts() async -> Set<String>
    /// Asks the App Store for the latest transactions. The system asks the customer to sign in.
    func sync() async throws
    /// One element for each new or changed transaction: Ask to Buy approvals, renewals, refunds, other devices.
    func transactionUpdates() -> AsyncStream<Void>
}

enum StoreError: Error {
    case productNotFound
    case unverified
}

/// The StoreKit 2 client.
final class AppStoreClient: StoreClient {
    private var products: [String: Product] = [:]

    func items(for ids: [String]) async throws -> [StoreItem] {
        for product in try await Product.products(for: ids) {
            products[product.id] = product
        }
        return ids.compactMap { products[$0] }.map { StoreItem(id: $0.id, displayPrice: $0.displayPrice) }
    }

    func purchase(_ id: String, with action: PurchaseAction?) async throws -> PurchaseOutcome {
        if products[id] == nil {
            _ = try await items(for: [id])
        }
        guard let product = products[id] else { throw StoreError.productNotFound }
        let result: Product.PurchaseResult
        do {
            result = if let action {
                try await action(product)
            } else {
                try await product.purchase()
            }
        } catch StoreKitError.userCancelled {
            return .cancelled
        }
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            return .purchased
        case .success(.unverified):
            throw StoreError.unverified
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func ownedProducts() async -> Set<String> {
        var owned: Set<String> = []
        for await entry in Transaction.currentEntitlements {
            if case let .verified(transaction) = entry, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        return owned
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    func transactionUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await entry in Transaction.updates {
                    if case let .verified(transaction) = entry {
                        await transaction.finish()
                    }
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
