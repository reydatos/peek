import PeekCore
import SwiftUI

/// The choice of the shot for the Match print: each shot of the set, with its score. The best match is the default.
/// The selected shot has a check and a border, so the color is not the only sign.
struct DuetShotPicker: View {
    @Bindable var model: BoothSessionModel

    /// The largest height of a shot in the row: 1.5 touch targets. A design value: the shots stay big enough to
    /// tell apart, and the print above them keeps its space on a tall display.
    static let thumbnailHeight = PeekTheme.touchTarget * 1.5

    var body: some View {
        if model.layout == .duetSingle, model.isComplete {
            let shots = model.finishedShots
            let percents = model.finishedShotPercents
            let selected = model.duetShotIndex
            HStack(alignment: .top, spacing: PeekTheme.tightSpace) {
                ForEach(shots.indices, id: \.self) { index in
                    let isSelected = index == selected
                    let percent = percents.indices.contains(index) ? percents[index] : nil
                    Button { model.duetSlot = index } label: {
                        VStack(spacing: PeekTheme.tightSpace / 2) {
                            Color.clear
                                .aspectRatio(3 / 4, contentMode: .fit)
                                .frame(maxHeight: Self.thumbnailHeight)
                                .overlay {
                                    Image(uiImage: shots[index])
                                        .resizable()
                                        .scaledToFill()
                                }
                                .clipShape(.rect(cornerRadius: PeekTheme.slotCorner))
                                .overlay {
                                    RoundedRectangle(cornerRadius: PeekTheme.slotCorner)
                                        .strokeBorder(isSelected ? PeekTheme.strong : Color.clear, lineWidth: 3)
                                }
                                .overlay(alignment: .topTrailing) {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(PeekTheme.onStrong, PeekTheme.strong)
                                            .padding(PeekTheme.tightSpace / 2)
                                            .accessibilityHidden(true)
                                    }
                                }
                            Text(verbatim: percent.map(BoothSessionModel.percentText) ?? "–")
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? PeekTheme.ink : PeekTheme.inkSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: PeekTheme.touchTarget)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(.shotNumber(index + 1)))
                    .accessibilityValue(Text(verbatim: percent.map(BoothSessionModel.percentText) ?? ""))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(.matchShotLabel))
        }
    }
}
