import SwiftUI

/// How the clip of the current pose shows over the camera picture.
enum ClipLook: Equatable {
    /// The small pose picture only.
    case corner
    /// The clip plays large, on a card over the picture.
    case large
    /// The clip covers the camera picture and is partly transparent. The people move until they cover it.
    case ghost
}

/// The design values of the clip over the camera picture. They are provisional: the owner sets them on the phone.
enum PoseClipTuning {
    /// How solid the ghost is, from 0 to 1.
    static let ghostOpacity = 0.4
    /// The values that the DEBUG control steps through.
    static let ghostOpacityChoices = [0.25, 0.4, 0.55, 0.7]
}

/// The ghost: the clip of the pose over the camera picture. It takes no touch, so the swipe and the zoom still work.
/// The photographer asked for it with a tap, so it plays with Reduce Motion on too.
struct PoseGhost: View {
    let url: URL
    let opacity: Double

    var body: some View {
        PoseClipView(url: url)
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The large clip of the pose, on a card over the camera picture, with the ghost button and the close button.
/// The automatic shutter stays on: the camera still sees the people, and a match must start the shot.
struct PoseClipCard: View {
    let model: BoothSessionModel
    let cue: PoseCue
    let url: URL

    var body: some View {
        VStack {
            Color.clear
                .overlay {
                    if let picture = cue.picture {
                        Image(uiImage: picture)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .overlay { PoseClipView(url: url) }
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: PeekTheme.slotCorner))
                .accessibilityElement()
                .accessibilityLabel(cue.name.text)
            HStack {
                Button { model.setClipLook(.ghost) } label: {
                    Label(.ghost, systemImage: "square.on.square.dashed")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
                Button { model.setClipLook(.corner) } label: {
                    PeekIconLabel(text: .close, systemImage: "xmark")
                }
            }
        }
        .padding(PeekTheme.tightSpace * 2)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .foregroundStyle(PeekTheme.ink)
    }
}

/// The pose picture as a button, when the pose has a clip: a tap plays the clip, and a second tap closes it.
struct PoseClipButton<Picture: View>: View {
    let model: BoothSessionModel
    @ViewBuilder let picture: Picture

    var body: some View {
        if model.canPlayClip {
            let isOpen = model.shownClipLook != .corner
            Button { model.togglePoseClip() } label: {
                picture
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: isOpen ? "xmark.circle.fill" : "play.circle.fill")
                            .font(.body)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(PeekTheme.ink, PeekTheme.surface)
                            .padding(PeekTheme.tightSpace / 2)
                    }
                    // The picture can be narrower than a finger.
                    .frame(minWidth: PeekTheme.touchTarget, minHeight: PeekTheme.touchTarget, alignment: .bottomLeading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isOpen ? .closePoseClip : .playPoseClip))
        } else {
            picture
        }
    }
}

#if DEBUG
    /// A control for the owner: each tap gives the ghost the next transparency value. It is not in the release build.
    struct GhostOpacityStepper: View {
        let model: BoothSessionModel

        var body: some View {
            Button {
                let choices = PoseClipTuning.ghostOpacityChoices
                let index = choices.firstIndex(of: model.ghostOpacity) ?? 0
                model.ghostOpacity = choices[(index + 1) % choices.count]
            } label: {
                Text(verbatim: "ghost \(Int(model.ghostOpacity * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .padding(PeekTheme.tightSpace)
                    .frame(minHeight: PeekTheme.touchTarget)
                    .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.chipCorner))
            }
            .buttonStyle(.plain)
            .foregroundStyle(PeekTheme.ink)
        }
    }
#endif
