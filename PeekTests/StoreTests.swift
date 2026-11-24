import Foundation
@testable import Peek
import PeekCore
import StoreKit
import Testing

/// The product table, the lock rule, and each state of the unlock sheet (5A), with a fake store.
@MainActor
struct StoreTests {
    let client = FakeStoreClient()
    let kids = PoseLibrary.packs.first { $0.id == "kidsPoses" }!
    let classic = PoseLibrary.packs.first { $0.id == PoseLibrary.classicID }!

    func started() async -> Entitlements {
        let entitlements = Entitlements(client: client)
        await entitlements.start()
        return entitlements
    }

    // MARK: The product table

    @Test func theProductTableMatchesTheStoreKitFile() throws {
        let file = try StoreKitFile.load()
        #expect(Set(StoreProducts.all) == file.productIDs)
        #expect(StoreProducts.all.count == file.productIDs.count)
    }

    @Test func theStoreKitFileHasTheOwnerPrices() throws {
        let file = try StoreKitFile.load()
        for id in StoreProducts.all where id != StoreProducts.allPacks {
            #expect(file.prices[id] == "1.99", "\(id)")
        }
        #expect(file.prices[StoreProducts.allPacks] == "19.99")
        #expect(file.allPacksPeriod == "P1Y")
        #expect(file.allPacksHasTrial == false)
    }

    @Test func streetStyleIsTheOneFreeBuiltInPackAndClassicIsPaid() {
        let free = PoseLibrary.packs.filter { $0.productID == nil }.map(\.id)
        #expect(free == [PoseLibrary.freeID])
        #expect(classic.productID == "com.a8media.peek.pack.classic")
        #expect(PoseCatalog().freePack.id == PoseLibrary.freeID)
    }

    @Test func aCustomerPackIsFree() {
        let pack = PosePack(id: "user-1", name: "Mine", cues: [])
        #expect(pack.productID == nil)
        #expect(StoreProducts.unlocks(pack, owned: []))
    }

    @Test func aPackProductUnlocksOnlyItsPackAndAllPacksUnlocksEveryPack() {
        let owned: Set = [StoreProducts.pack("kidsPoses")]
        #expect(StoreProducts.unlocks(kids, owned: owned))
        #expect(!StoreProducts.unlocks(classic, owned: owned))
        for pack in PoseLibrary.packs {
            #expect(StoreProducts.unlocks(pack, owned: [StoreProducts.allPacks]))
        }
    }

    // MARK: Entitlements

    @Test func aPaidPackIsLockedUntilTheFirstReadEnds() async {
        client.owned = [StoreProducts.pack("kidsPoses")]
        let entitlements = Entitlements(client: client)
        #expect(!entitlements.isLoaded)
        #expect(!entitlements.isUnlocked(kids))
        #expect(entitlements.isUnlocked(PoseCatalog().freePack))
        await entitlements.start()
        #expect(entitlements.isUnlocked(kids))
        #expect(!entitlements.isUnlocked(classic))
    }

    @Test func subscribedUnlocksEveryPack() async {
        client.owned = [StoreProducts.allPacks]
        let entitlements = await started()
        #expect(entitlements.hasAllPacks)
        #expect(PoseLibrary.packs.allSatisfy(entitlements.isUnlocked))
    }

    @Test func anExpiryLocksThePackAtTheNextRead() async {
        client.owned = [StoreProducts.allPacks]
        let entitlements = await started()
        client.owned = []
        await entitlements.refresh()
        #expect(!entitlements.isUnlocked(kids))
    }

    // MARK: Unlock sheet states (5A)

    @Test func pricesLoadingThenLoaded() async {
        let entitlements = await started()
        // Before the prices load, the buttons have no price and are disabled.
        #expect(entitlements.prices == .loading)
        #expect(entitlements.price(of: StoreProducts.pack("kidsPoses")) == nil)
        await entitlements.loadPrices()
        #expect(entitlements.price(of: StoreProducts.pack("kidsPoses")) == "$1.99")
        #expect(entitlements.price(of: StoreProducts.allPacks) == "$19.99")
    }

    @Test func pricesFailedThenTryAgain() async {
        client.itemsError = FakeStoreError()
        let entitlements = await started()
        await entitlements.loadPrices()
        #expect(entitlements.prices == .failed)
        client.itemsError = nil
        await entitlements.loadPrices()
        #expect(entitlements.price(of: StoreProducts.allPacks) == "$19.99")
    }

    @Test func cancelledChangesNothing() async throws {
        client.purchaseResult = .success(.cancelled)
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        try await flow.buy(#require(kids.productID))
        #expect(flow.phase == .idle)
        #expect(flow.notice == nil)
        #expect(!flow.isUnlocked)
    }

    @Test func askToBuyWaitsThenAnApprovalUnlocks() async throws {
        client.purchaseResult = .success(.pending)
        let entitlements = await started()
        let flow = UnlockFlow(pack: kids, entitlements: entitlements)
        try await flow.buy(#require(kids.productID))
        #expect(try flow.isWaiting(#require(kids.productID)))
        #expect(flow.phase == .idle)
        #expect(!flow.isUnlocked)

        // Approved later: the approval arrives through the transaction listener.
        try client.sendUpdate(owned: [#require(kids.productID)])
        #expect(await eventually { flow.isUnlocked })
        #expect(try !flow.isWaiting(#require(kids.productID)))
        flow.noteUnlock()
        #expect(flow.phase == .succeeded)
    }

    @Test func failedShowsTheBannerAndTryAgainBuysTheSameProduct() async throws {
        client.purchaseResult = .failure(FakeStoreError())
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        try await flow.buy(#require(kids.productID))
        #expect(flow.notice == .purchaseFailed)
        #expect(flow.phase == .idle)

        client.purchaseResult = .success(.purchased)
        try await flow.buy(#require(flow.lastProductID))
        #expect(try client.purchases == [#require(kids.productID), #require(kids.productID)])
        #expect(flow.notice == nil)
        #expect(flow.phase == .succeeded)
    }

    @Test func successUnlocksThePack() async throws {
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        try await flow.buy(#require(kids.productID))
        #expect(flow.phase == .succeeded)
        #expect(flow.isUnlocked)
    }

    @Test func allPacksFromTheSheetUnlocksThePack() async {
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.buy(StoreProducts.allPacks)
        #expect(flow.phase == .succeeded)
        #expect(flow.entitlements.hasAllPacks)
    }

    @Test func restoreNothingFound() async {
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.restore()
        #expect(client.syncCount == 1)
        #expect(flow.notice == .nothingToRestore)
        #expect(flow.phase == .idle)
    }

    @Test func restoreFoundAnotherPackKeepsTheSheet() async throws {
        client.syncFinds = try [#require(classic.productID)]
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.restore()
        #expect(flow.notice == .restored)
        #expect(flow.phase == .idle)
        #expect(flow.entitlements.isUnlocked(classic))
    }

    @Test func restoreFoundThisPackSucceeds() async throws {
        client.syncFinds = try [#require(kids.productID)]
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.restore()
        #expect(flow.notice == .restored)
        #expect(flow.phase == .succeeded)
    }

    @Test func aClosedSignInIsNotAFailure() async {
        client.syncError = StoreKitError.userCancelled
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.restore()
        #expect(flow.notice == nil)
        #expect(flow.phase == .idle)
    }

    @Test func restoreFailed() async {
        client.syncError = FakeStoreError()
        let flow = await UnlockFlow(pack: kids, entitlements: started())
        await flow.restore()
        #expect(flow.notice == .restoreFailed)
    }

    // MARK: Gates (3A, D5)

    @Test func aTapOnAPackCard() {
        #expect(PackChoice(isUnlocked: false, hasShots: false) == .unlock)
        #expect(PackChoice(isUnlocked: false, hasShots: true) == .unlock)
        #expect(PackChoice(isUnlocked: true, hasShots: true) == .confirmDiscard)
        #expect(PackChoice(isUnlocked: true, hasShots: false) == .load)
    }

    @Test func aDraftOnAnExpiredPackFinishesAndNewSetAsksForTheUnlock() async {
        let store = FileDraftStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        let first = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), drafts: store, sleep: { _ in })
        await first.startCamera()
        first.loadPack("kidsPoses")
        first.send(.start)
        await first.countdownTask?.value
        await first.captureTask?.value
        first.send(.accept)
        await first.persistTask?.value

        // All Packs ended while the app was closed. The draft keeps its pack, so the set can finish.
        let second = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), drafts: store, sleep: { _ in })
        second.isUnlocked = { $0.productID == nil }
        await second.restoreDraft()
        await second.startCamera()
        #expect(second.packID == "kidsPoses")
        #expect(second.hasShots)

        // New set is the next check point: it asks for the unlock and keeps the set.
        second.startNewSet()
        #expect(second.unlockRequest?.id == "kidsPoses")
        #expect(second.hasShots)
    }

    @Test func newSetWithAnUnlockedPackStartsAtOnce() async {
        let model = BoothSessionModel(capture: FakeCapture(), packID: "kidsPoses", saver: FakeSaver(), sleep: { _ in })
        model.isUnlocked = { _ in true }
        await model.startCamera()
        model.startNewSet()
        #expect(model.unlockRequest == nil)
        #expect(model.packID == "kidsPoses")
    }
}

/// The parts of `Config/Products.storekit` that the tests check.
struct StoreKitFile {
    var productIDs: Set<String> = []
    var prices: [String: String] = [:]
    var allPacksPeriod: String?
    var allPacksHasTrial = false

    static var url: URL {
        get throws {
            try #require(Bundle(for: BundleToken.self).url(forResource: "Products", withExtension: "storekit"))
        }
    }

    static func load() throws -> StoreKitFile {
        let json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var file = StoreKitFile()
        let products = json["products"] as? [[String: Any]] ?? []
        let groups = json["subscriptionGroups"] as? [[String: Any]] ?? []
        let subscriptions = groups.flatMap { $0["subscriptions"] as? [[String: Any]] ?? [] }
        for product in products + subscriptions {
            guard let id = product["productID"] as? String else { continue }
            file.productIDs.insert(id)
            file.prices[id] = product["displayPrice"] as? String
            if id == StoreProducts.allPacks {
                file.allPacksPeriod = product["recurringSubscriptionPeriod"] as? String
                file.allPacksHasTrial = !(product["introductoryOffer"] is NSNull || product["introductoryOffer"] == nil)
            }
        }
        return file
    }
}

private final class BundleToken {}
