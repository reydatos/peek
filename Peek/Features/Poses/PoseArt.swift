import SwiftUI
import UIKit

/// The reference picture of a pose, or a symbol when the app has no picture for it.
struct PoseArt: View {
    let cue: PoseCue

    var body: some View {
        PeekTheme.panel
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
                        .foregroundStyle(PeekTheme.mist)
                }
            }
            .clipShape(.rect(cornerRadius: PeekTheme.smallCorner))
            .accessibilityLabel(Text(cue.name))
    }
}
