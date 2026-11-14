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
                    let cell = SlotCell(
                        number: number,
                        image: model.image(for: slot),
                        isCurrent: slot.id == model.state.currentSlotID
                    )
                    if axis == .vertical {
                        // Four cells use four tenths of the height. The pose reference uses the remainder.
                        cell.containerRelativeFrame(.vertical, count: 10, spacing: 0)
                    } else {
                        cell
                    }
                }
                // The style keeps the full color of a slot with no shot. The plain style dims a disabled button.
                .buttonStyle(SlotButtonStyle())
                .disabled(slot.acceptedTake == nil)
                .accessibilityLabel(Text(.retakeShotNumber(number)))
            }
        }
    }
}
