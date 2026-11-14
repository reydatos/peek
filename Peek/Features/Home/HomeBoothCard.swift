import SwiftUI

/// The booth entry: the wordmark, a sample picture, the red start button, and the draft.
struct HomeBoothCard: View {
    let hasDraft: Bool
    let onStart: () -> Void
    let onResume: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkHeight = 40

    var body: some View {
        VStack(alignment: .leading) {
            Image("peek-wordmark")
                .resizable()
                .scaledToFit()
                .frame(height: wordmarkHeight)
                .accessibilityLabel(Text(.appName))
            // A stored picture, not the camera. The camera starts in the booth.
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    Image("pose-smile")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: PeekTheme.smallCorner))
                .accessibilityHidden(true)
            Button(action: onStart) {
                HStack {
                    Text(.startBooth)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(PeekPrimaryButtonStyle(isBoothEntry: true))
            if hasDraft {
                Button(action: onResume) {
                    Text(.resumeDraft)
                }
                .buttonStyle(PeekSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
