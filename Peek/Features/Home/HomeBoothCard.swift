import SwiftUI

/// The booth entry: the wordmark, a sample picture, the booth type, the red start button, and the draft.
struct HomeBoothCard: View {
    @Binding var isCopycat: Bool
    /// The pack that Start a Booth opens.
    let pack: PosePack
    let hasDraft: Bool
    let onStart: () -> Void
    let onResume: () -> Void
    /// False on a tall display: the actions are then at the bottom of the screen, below the pack list.
    var showsActions = true
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkHeight = 40

    var body: some View {
        VStack(alignment: .leading) {
            Image("peek-wordmark")
                .resizable()
                .foregroundStyle(PeekTheme.wordmark)
                .scaledToFit()
                .frame(height: wordmarkHeight)
                .accessibilityLabel(Text(.appName))
            // A stored picture, not the camera. The camera starts in the booth, after an explicit action.
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    Image(pack.cues.first?.assetName ?? "pose-smile")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: PeekTheme.photoCorner))
                .accessibilityHidden(true)
            PeekSegmentedChoice(selection: $isCopycat, options: [(false, .classic), (true, .copycat)])
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(.boothKind))
            if showsActions {
                HomeActions(pack: pack, hasDraft: hasDraft, onStart: onStart, onResume: onResume)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
