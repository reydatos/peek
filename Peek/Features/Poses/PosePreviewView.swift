import SwiftUI

/// The replay of one recorded pose in the pack editor: the clip plays again and again, large.
struct PosePreviewView: View {
    let poseNumber: Int
    /// The JPEG bytes of the last frame of the clip.
    let still: Data
    let clipURL: URL
    let onDone: () -> Void
    let onRecordAgain: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack {
            Text(.poseNumber(poseNumber))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            // The customer asked for this clip with the play button, so it plays with Reduce Motion on too.
            PoseClipPicture(still: still, clipURL: clipURL)
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: PeekTheme.photoCorner))
                .accessibilityElement()
                .accessibilityLabel(Text(.recordedClip(poseNumber)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            // At a large text size the two buttons do not fit side by side, so one is above the other.
            let layout = dynamicTypeSize >= .xxLarge ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
            layout {
                Button(action: onRecordAgain) {
                    Label(.recordAgain, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
                Button(action: onDone) {
                    Label(.done, systemImage: "checkmark")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
            }
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.page)
    }
}
