import SwiftUI
import UIKit

/// The reference picture of a pose, or a symbol when the app has no picture for it.
struct PoseArt: View {
    let cue: PoseCue

    var body: some View {
        PeekTheme.fill
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if let picture = UIImage(named: cue.assetName) {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: cue.symbol)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
            }
            .clipShape(.rect(cornerRadius: PeekTheme.smallPhotoCorner))
            .accessibilityLabel(Text(cue.name))
    }
}
