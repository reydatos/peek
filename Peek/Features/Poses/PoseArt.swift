import SwiftUI
import UIKit

/// The reference picture of a pose, or a symbol when the app has no picture for it.
struct PoseArt: View {
    let cue: PoseCue

    var body: some View {
        Color.secondary.opacity(0.2)
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
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityLabel(Text(cue.name))
    }
}
