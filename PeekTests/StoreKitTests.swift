@testable import Peek
import StoreKit
import StoreKitTest
import Testing

/// The StoreKit client against the local store of `Config/Products.storekit`.
/// The test environment is one shared instance, so the tests run one at a time.
@MainActor
@Suite(.serialized) struct StoreKitTests {
    let session: SKTestSession
    let client = AppStoreClient()
    let allPacksID = StoreProducts.allPacks

    init() throws {
        session = try SKTestSession(contentsOf: StoreKitFile.url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        session.timeRate = .realTime
    }

    @Test func everyProductLoads() async throws {
        let items = try await client.items(for: StoreProducts.all)
        #expect(Set(items.map(\.id)) == Set(StoreProducts.all))
    }

    @Test func aPurchaseIsOwned() async throws {
        #expect(try await client.purchase(allPacksID, with: nil) == .purchased)
        #expect(await client.ownedProducts() == [allPacksID])
    }

    @Test func askToBuyIsPendingUntilAParentApproves() async throws {
        session.askToBuyEnabled = true
        let entitlements = Entitlements(client: client)
        await entitlements.start()
        let kids = try #require(PoseLibrary.packs.first { $0.id == "kidsPoses" })

        #expect(try await entitlements.purchase(allPacksID) == .pending)
        #expect(entitlements.waiting == [allPacksID])
        #expect(!entitlements.isUnlocked(kids))

        let transaction = try #require(session.allTransactions().first { $0.productIdentifier == allPacksID })
        try session.approveAskToBuyTransaction(identifier: transaction.identifier)
        // The approval arrives through the listener that starts at launch.
        #expect(await eventually { entitlements.isUnlocked(kids) })
        #expect(entitlements.waiting.isEmpty)
    }

    @Test func aFailedPurchaseThrows() async throws {
        try await session.setSimulatedError(.generic(.unknown), forAPI: .purchase)
        await #expect(throws: (any Error).self) {
            _ = try await client.purchase(allPacksID, with: nil)
        }
        try await session.setSimulatedError(nil, forAPI: .purchase)
        #expect(await client.ownedProducts().isEmpty)
    }

    @Test func aRefundedSubscriptionIsNotOwned() async throws {
        #expect(try await client.purchase(allPacksID, with: nil) == .purchased)
        let transaction = try #require(session.allTransactions().first { $0.productIdentifier == allPacksID })
        let entitlements = Entitlements(client: client)
        await entitlements.start()
        try session.refundTransaction(identifier: transaction.identifier)
        // The listener sees the refund without a manual read.
        #expect(await eventually { entitlements.owned.isEmpty })
    }

    @Test func anExpiredSubscriptionLocksThePackAtTheNextRead() async throws {
        // Every subscription renews every 2 seconds, so an expiry comes in seconds, not in a year.
        session.timeRate = .oneRenewalEveryTwoSeconds
        let entitlements = Entitlements(client: client)
        await entitlements.start()
        let kids = try #require(PoseLibrary.packs.first { $0.id == "kidsPoses" })
        #expect(try await entitlements.purchase(allPacksID) == .purchased)
        #expect(entitlements.isUnlocked(kids))

        let transaction = try #require(session.allTransactions().first { $0.productIdentifier == allPacksID })
        try session.disableAutoRenewForTransaction(identifier: transaction.identifier)
        var isLocked = false
        for _ in 0 ..< 20 where !isLocked {
            try await Task.sleep(for: .milliseconds(500))
            await entitlements.refresh()
            isLocked = !entitlements.isUnlocked(kids)
        }
        #expect(isLocked)
        session.timeRate = .realTime
    }
}
