import SwiftUI

/// The time remaining. The subject-facing form is large and at the bottom, so the numeral stays below faces.
struct CountdownView: View {
    let remaining: Int
    let isSubjectFacing: Bool

    var body: some View {
        if isSubjectFacing {
            Text(remaining, format: .number)
                .font(PeekFont.sans(.largeTitle))
                .bold()
                .monospacedDigit()
                .scaleEffect(3, anchor: .bottom)
                .foregroundStyle(Color.white)
                .shadow(color: PeekTheme.ink, radius: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
        } else {
            Text(remaining, format: .number)
                .font(PeekFont.sans(.largeTitle))
                .bold()
                .monospacedDigit()
                .padding()
                .foregroundStyle(Color.white)
                .background(PeekTheme.panel, in: .circle)
        }
    }
}

#Preview("Subject") {
    CountdownView(remaining: 3, isSubjectFacing: true)
}
