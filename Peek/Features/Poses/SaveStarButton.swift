import SwiftUI

/// The star that saves a pose or removes it from Saved. The filled star and the label state the condition.
struct SaveStarButton: View {
    let cue: PoseCue
    @Environment(SavedPoses.self) private var saved

    var body: some View {
        let isSaved = saved.contains(cue.id)
        Button { saved.toggle(cue.id) } label: {
            Label(isSaved ? .removeSavedPose : .savePose, systemImage: isSaved ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .font(.footnote)
                .foregroundStyle(PeekTheme.ink)
                .padding(PeekTheme.tightSpace)
                .background(PeekTheme.surface, in: .circle)
                .frame(minWidth: PeekTheme.touchTarget, minHeight: PeekTheme.touchTarget, alignment: .topTrailing)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
