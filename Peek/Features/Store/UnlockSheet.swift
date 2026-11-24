import StoreKit
import SwiftUI

/// The unlock sheet of a paid pack (3A, 5A, 12A). It shows the poses before the customer pays.
/// It shows on the inner display only: purchase prompts stay off the outer display.
struct UnlockSheet: View {
    /// The pause between the check on the button and the close of the sheet. This is a design value.
    static let successPause = Duration.milliseconds(800)

    let onUnlocked: () -> Void
    @State private var flow: UnlockFlow
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(pack: PosePack, entitlements: Entitlements, onUnlocked: @escaping () -> Void) {
        self.init(flow: UnlockFlow(pack: pack, entitlements: entitlements), onUnlocked: onUnlocked)
    }

    /// A sheet with a given state, for previews and render checks.
    init(flow: UnlockFlow, onUnlocked: @escaping () -> Void = {}) {
        _flow = State(initialValue: flow)
        self.onUnlocked = onUnlocked
    }

    private var pack: PosePack {
        flow.pack
    }

    private var entitlements: Entitlements {
        flow.entitlements
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // A wide sheet puts the poses beside the offer, so the buttons stay in view.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PeekTheme.tightSpace * 4) {
                        poses
                            .frame(width: Self.posesWidth)
                        // The ideal width keeps the long terms line from asking for one wide row.
                        details
                            .frame(minWidth: Self.detailsMinWidth, idealWidth: Self.detailsMinWidth, maxWidth: .infinity)
                    }
                    VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 3) {
                        poses
                            .frame(maxWidth: Self.posesWidth)
                        details
                    }
                }
                .padding()
            }
            .background(PeekTheme.page)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(.close) }
                }
            }
        }
        .task {
            if entitlements.price(of: StoreProducts.allPacks) == nil {
                await entitlements.loadPrices()
            }
        }
        // An Ask to Buy approval or a purchase on another device unlocks the pack while the sheet is open.
        .onChange(of: flow.isUnlocked) { _, isUnlocked in
            if isUnlocked {
                flow.noteUnlock()
            }
        }
        .task(id: flow.phase == .succeeded) {
            guard flow.phase == .succeeded else { return }
            try? await Task.sleep(for: Self.successPause)
            onUnlocked()
        }
    }

    /// The width of the pose pictures, and the least width of the offer beside them. These are design values.
    static let posesWidth: CGFloat = 260
    static let detailsMinWidth: CGFloat = 280

    private var poses: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PeekTheme.tightSpace) {
            ForEach(pack.cues.prefix(4)) { cue in
                PoseArt(cue: cue, cornerRadius: PeekTheme.slotCorner)
                    .accessibilityHidden(true)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 3) {
            pack.name.text
                .font(.title2)
                .bold()
                .foregroundStyle(PeekTheme.ink)
            lines
            if let notice = flow.notice {
                banner(for: notice)
            }
            offers
        }
    }

    /// Lines from the pack itself: the pose names and "Included in All Packs" (12A).
    private var lines: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace) {
            ForEach(pack.cues) { cue in
                Label { cue.name.text } icon: { Image(systemName: "checkmark") }
            }
            // Only a pack with a clip for each pose has a video guide.
            if pack.cues.allSatisfy(\.hasMove) {
                Label(.unlockVideoGuide, systemImage: "play.rectangle")
            }
            Label(.unlockIncludedInAllPacks, systemImage: "square.stack")
        }
        .font(.body)
        .foregroundStyle(PeekTheme.ink)
    }

    @ViewBuilder private var offers: some View {
        if entitlements.prices == .failed {
            VStack(alignment: .leading) {
                Text(.unlockPricesFailed)
                    .foregroundStyle(PeekTheme.ink)
                Button { Task { await entitlements.loadPrices() } } label: { Text(.tryAgain) }
                    .buttonStyle(PeekSecondaryButtonStyle())
            }
        } else {
            VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
                if let productID = pack.productID {
                    offerButton(productID, isPrimary: true) { price in
                        price.map { Text(.unlockForPrice($0)) } ?? Text(.unlockPack)
                    }
                }
                offerButton(StoreProducts.allPacks, isPrimary: false) { price in
                    price.map { Text(.allPacksForPrice($0)) } ?? Text(.allPacks)
                }
                subscriptionTerms
                Button { Task { await flow.restore() } } label: {
                    HStack {
                        Text(.restorePurchases)
                        if flow.phase == .restoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(flow.isBusy)
                .frame(minHeight: PeekTheme.touchTarget)
                .foregroundStyle(PeekTheme.ink)
            }
        }
    }

    /// The offer of one product. The pack is the red main action; All Packs is secondary.
    @ViewBuilder
    private func offerButton(
        _ productID: String,
        isPrimary: Bool,
        label: @escaping (String?) -> Text
    ) -> some View {
        let price = entitlements.price(of: productID)
        if flow.isWaiting(productID) {
            // Ask to Buy: the button turns grey until a parent answers. The lock stays on the card.
            Button {} label: { Label(.unlockWaitingForParent, systemImage: "clock") }
                .buttonStyle(PeekPrimaryButtonStyle())
                .disabled(true)
        } else {
            let button = Button {
                Task { await flow.buy(productID, with: purchase) }
            } label: {
                HStack {
                    label(price)
                    Spacer(minLength: 0)
                    if flow.phase == .succeeded, flow.lastProductID == productID {
                        Image(systemName: "checkmark")
                            .symbolEffect(.bounce, options: .nonRepeating, isActive: !reduceMotion)
                            .accessibilityLabel(Text(.packUnlocked))
                    } else if price == nil || flow.phase == .buying(productID) {
                        ProgressView()
                    }
                }
            }
            .disabled(price == nil || flow.isBusy)
            if isPrimary {
                button.buttonStyle(PeekPrimaryButtonStyle())
            } else {
                button.buttonStyle(PeekSecondaryButtonStyle())
            }
        }
    }

    /// The subscription terms and links that App Review guideline 3.1.2 asks for.
    private var subscriptionTerms: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace) {
            if let price = entitlements.price(of: StoreProducts.allPacks) {
                Text(.allPacksTerms(price))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Link(destination: StoreProducts.termsURL) { Text(.termsOfUse) }
                Link(destination: StoreProducts.privacyURL) { Text(.privacyPolicy) }
            }
            .underline()
        }
        .font(.footnote)
        .foregroundStyle(PeekTheme.inkSecondary)
    }

    @ViewBuilder
    private func banner(for notice: UnlockFlow.Notice) -> some View {
        switch notice {
        case .purchaseFailed:
            PeekBanner(text: .purchaseFailed) {
                if let productID = flow.lastProductID {
                    Button { Task { await flow.buy(productID, with: purchase) } } label: { Text(.tryAgain) }
                        .buttonStyle(PeekSecondaryButtonStyle())
                }
            }
        case .restored:
            PeekBanner(text: .restoreDone, systemImage: "checkmark.circle")
        case .nothingToRestore:
            PeekBanner(text: .restoreNothingFound, systemImage: "info.circle")
        case .restoreFailed:
            PeekBanner(text: .restoreFailed)
        }
    }
}
