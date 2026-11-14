import SwiftUI

/// The time remaining: the numeral with pips beside it. A filled pip is one second that remains.
/// It goes below the photo, so the numeral never covers a face.
struct CountdownView: View {
    let remaining: Int
    /// The full length of the countdown.
    let total: Int
    /// The large form is for the people in the photo. It reads at portrait distance.
    var isLarge = false
    @ScaledMetric(relativeTo: .largeTitle) private var largeSize = 120
    @ScaledMetric(relativeTo: .title) private var pip = 12

    var body: some View {
        HStack(spacing: pip) {
            Text(remaining, format: .number)
                .font(isLarge ? .system(size: largeSize, weight: .bold) : .largeTitle.bold())
                .monospacedDigit()
                .foregroundStyle(PeekTheme.ink)
            VStack(spacing: pip / 2) {
                ForEach(0 ..< max(total, 1), id: \.self) { index in
                    Circle()
                        .fill(index < remaining ? PeekTheme.strong : PeekTheme.fill)
                        .overlay { Circle().strokeBorder(PeekTheme.separator) }
                        .frame(width: pip, height: pip)
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.secondsLeft(remaining)))
    }
}

#Preview("Subject") {
    CountdownView(remaining: 2, total: 3, isLarge: true)
}
