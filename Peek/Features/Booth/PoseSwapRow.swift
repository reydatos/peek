import SwiftUI

/// The poses of the pack. A tap swaps the pose of the current shot. The outer display follows.
struct PoseSwapRow: View {
    let model: BoothSessionModel

    var body: some View {
        HStack(alignment: .top) {
            ForEach(model.packCues) { cue in
                Button { model.swapPose(to: cue.id) } label: {
                    VStack(alignment: .leading) {
                        PoseArt(cue: cue)
                            .overlay {
                                if cue.id == model.currentCue?.id {
                                    Rectangle().strokeBorder(PeekTheme.accent, lineWidth: 2)
                                }
                            }
                        Text(cue.name)
                            .font(.caption)
                            .lineLimit(2, reservesSpace: true)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(cue.id == model.currentCue?.id ? .isSelected : [])
            }
            Button { model.shufflePose() } label: {
                Label(.shuffle, systemImage: "shuffle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(PeekGhostButtonStyle())
        }
        .disabled(model.state.phase != .ready)
    }
}
