import SwiftUI

/// The four progress bars of the set. An accepted shot is a full bar, the current shot has the pack accent,
/// and an open shot is a dim bar. A tap on an accepted shot starts a retake of that slot only.
struct ShotProgressBars: View {
    let model: BoothSessionModel
    @ScaledMetric(relativeTo: .caption) private var height = 4

    var body: some View {
        HStack(spacing: PeekTheme.tightSpace) {
            ForEach(model.state.slots) { slot in
                let number = slot.id.index + 1
                let isCurrent = slot.id == model.state.currentSlotID
                let isAccepted = slot.acceptedTake != nil
                Button { model.send(.retake(slot.id)) } label: {
                    Capsule()
                        .fill(isCurrent ? model.accent : isAccepted ? PeekTheme.strong : PeekTheme.fill)
                        .frame(height: height)
                        // The bar is thin. The touch target is 44 points high.
                        .frame(maxWidth: .infinity, minHeight: PeekTheme.touchTarget)
                        .contentShape(.rect)
                }
                .buttonStyle(SlotButtonStyle())
                .disabled(!isAccepted)
                .accessibilityLabel(Text(isAccepted ? .retakeShotNumber(number) : .shotNumber(number)))
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
        }
    }
}
