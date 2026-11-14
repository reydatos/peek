import SwiftUI

/// One position in the slot rail. It has three states, and each state has a sign that is not a color:
/// an accepted slot has a check, the current slot has its number and a ring, an empty slot has its number.
struct SlotCell: View {
    let number: Int
    let isAccepted: Bool
    let isCurrent: Bool
    /// The accent of the pack. It fills the current slot.
    let accent: Color
    @ScaledMetric(relativeTo: .caption) private var width = 26
    @ScaledMetric(relativeTo: .caption) private var height = 34

    var body: some View {
        RoundedRectangle(cornerRadius: PeekTheme.slotCorner)
            .fill(isCurrent ? accent : isAccepted ? PeekTheme.strong : PeekTheme.fill)
            .frame(width: width, height: height)
            .overlay {
                if isAccepted, !isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(PeekTheme.onStrong)
                } else {
                    Text(number, format: .number)
                        .foregroundStyle(isCurrent ? PeekTheme.paperInk : PeekTheme.inkSecondary)
                }
            }
            .font(.caption)
            .bold()
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: PeekTheme.slotCorner)
                        .strokeBorder(PeekTheme.strong, lineWidth: 2)
                }
            }
    }
}

#Preview {
    HStack {
        SlotCell(number: 1, isAccepted: true, isCurrent: false, accent: PeekTheme.cyan)
        SlotCell(number: 2, isAccepted: false, isCurrent: true, accent: PeekTheme.cyan)
        SlotCell(number: 3, isAccepted: false, isCurrent: false, accent: PeekTheme.cyan)
    }
    .padding()
    .background(PeekTheme.page)
}
