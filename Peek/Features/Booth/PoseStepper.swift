import SwiftUI

/// The pose picture with a button at each side that changes the pose, and a dot for each pose of the pack below it.
/// The sideways swipe on the photo does the same. The buttons show that the pose can change, and VoiceOver can use
/// them (owner request, 2026-11-20). They show only while the booth waits for a shot.
struct PoseStepper<Picture: View>: View {
    let model: BoothSessionModel
    @ViewBuilder let picture: Picture

    var body: some View {
        if model.canStepPose {
            VStack(spacing: PeekTheme.tightSpace) {
                HStack(spacing: 0) {
                    arrow(.previousPose, systemImage: "chevron.left", offset: -1)
                    picture
                    arrow(.nextPose, systemImage: "chevron.right", offset: 1)
                }
                PoseDots(count: model.packCues.count, current: model.packCues.firstIndex { $0.id == model.currentCue?.id })
            }
        } else {
            picture
        }
    }

    private func arrow(_ label: LocalizedStringResource, systemImage: String, offset: Int) -> some View {
        Button { model.stepPose(by: offset) } label: {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(PeekTheme.ink)
                .padding(PeekTheme.tightSpace)
                .background(PeekTheme.surface, in: .circle)
                .frame(minWidth: PeekTheme.touchTarget, minHeight: PeekTheme.touchTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
