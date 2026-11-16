import SwiftUI
import UIKit

/// The reference picture of a pose, or a symbol when the app has no picture for it.
///
/// A pose with a start picture can show its move: the art changes between the start and the final pose.
/// With Reduce Motion on, it shows the final pose only.
struct PoseArt: View {
    let cue: PoseCue
    var cornerRadius = PeekTheme.smallPhotoCorner
    /// True where the character shows the move. Small copies of the art stay still.
    var showsMove = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The time that each of the two pictures stays. This is a design value.
    static let stepSeconds = 0.9

    var body: some View {
        PeekTheme.fill
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if let picture = cue.picture {
                    if showsMove, !reduceMotion, let start = cue.startPicture {
                        TimelineView(.periodic(from: .now, by: Self.stepSeconds)) { context in
                            let step = Int(context.date.timeIntervalSinceReferenceDate / Self.stepSeconds)
                            ZStack {
                                fill(start)
                                fill(picture)
                                    .opacity(step.isMultiple(of: 2) ? 1 : 0)
                            }
                            .animation(.easeInOut, value: step)
                        }
                    } else {
                        fill(picture)
                    }
                } else {
                    Image(systemName: cue.symbol)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .accessibilityLabel(cue.name.text)
    }

    private func fill(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
    }
}
