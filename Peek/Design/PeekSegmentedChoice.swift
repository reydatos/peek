import SwiftUI

/// A choice between a few values: a pill in the fill color, with the selected segment in the strong color.
/// The selected segment has a check, so the color is not the only sign.
struct PeekSegmentedChoice<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: LocalizedStringResource)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button { selection = option.value } label: {
                    HStack(spacing: PeekTheme.tightSpace) {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                        Text(option.label)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: PeekTheme.touchTarget)
                    .foregroundStyle(isSelected ? PeekTheme.onStrong : PeekTheme.ink)
                    .background(isSelected ? PeekTheme.strong : Color.clear, in: .capsule)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .background(PeekTheme.fill, in: .capsule)
    }
}
