import SwiftUI

/// The four slots of the sequence. A tap on an accepted shot starts a retake of that slot only.
struct SlotRail: View {
    let model: BoothSessionModel

    var body: some View {
        HStack {
            ForEach(model.state.slots) { slot in
                Button { model.send(.retake(slot.id)) } label: {
                    SlotCell(
                        number: slot.id.index + 1,
                        image: model.image(for: slot),
                        isCurrent: slot.id == model.state.currentSlotID
                    )
                }
                .buttonStyle(.plain)
                .disabled(slot.acceptedTake == nil)
                .accessibilityLabel(Text(.retakeShot) + Text(verbatim: " \(slot.id.index + 1)"))
            }
        }
    }
}
