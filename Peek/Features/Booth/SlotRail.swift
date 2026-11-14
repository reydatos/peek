import SwiftUI

/// The four slots of the sequence. A tap on an accepted shot starts a retake of that slot only.
struct SlotRail: View {
    let model: BoothSessionModel
    let axis: Axis

    var body: some View {
        let layout = axis == .vertical ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())
        layout {
            ForEach(model.state.slots) { slot in
                let number = slot.id.index + 1
                Button { model.send(.retake(slot.id)) } label: {
                    SlotCell(
                        number: number,
                        isAccepted: slot.acceptedTake != nil,
                        isCurrent: !model.isComplete && slot.id == model.state.currentSlotID,
                        accent: model.pack?.accent ?? PeekTheme.strong
                    )
                    // The slot is small. The touch target is 44 points or more.
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
                }
                // The style keeps the full color of a slot with no shot. The plain style dims a disabled button.
                .buttonStyle(SlotButtonStyle())
                .disabled(slot.acceptedTake == nil)
                .accessibilityLabel(Text(.retakeShotNumber(number)))
            }
        }
    }
}
