import SwiftUI

/// The time remaining. The subject-facing form is large and at the bottom, so the numeral stays below faces.
struct CountdownView: View {
    let remaining: Int
    let isSubjectFacing: Bool

    var body: some View {
        if isSubjectFacing {
            Text(remaining, format: .number)
                .font(.largeTitle)
                .bold()
                .monospacedDigit()
                .scaleEffect(3, anchor: .bottom)
                .foregroundStyle(Color.white)
                .shadow(color: PeekTheme.scrim, radius: 8)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
        } else {
            Text(remaining, format: .number)
                .font(.largeTitle)
                .bold()
                .monospacedDigit()
                .padding()
                .foregroundStyle(PeekTheme.ink)
                .background(PeekTheme.surface, in: .circle)
        }
    }
}

#Preview("Subject") {
    CountdownView(remaining: 3, isSubjectFacing: true)
}
