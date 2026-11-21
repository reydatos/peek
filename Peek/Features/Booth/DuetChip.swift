import SwiftUI

/// The chip on the camera screen that turns the duet video on and off. It shows only for a pack with clips, while
/// the booth waits for a shot. The switch in the More menu is the same setting, and both are off at each start of
/// the app (owner decisions, 2026-11-17 and 2026-11-21).
struct DuetChip: View {
    let model: BoothSessionModel

    var body: some View {
        if model.showsDuetChip {
            let isOn = model.isDuetOn
            Button { model.toggleDuet() } label: {
                Label(.duetChip, systemImage: "rectangle.split.1x2")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal)
                    .frame(minHeight: PeekTheme.touchTarget)
                    .foregroundStyle(isOn ? PeekTheme.onStrong : PeekTheme.ink)
                    .background(isOn ? PeekTheme.strong : PeekTheme.surface, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.duetVideo))
            .accessibilityAddTraits(isOn ? .isSelected : [])
        }
    }
}
