import SwiftUI

/// The time remaining. The subject-facing form fills the display so it reads at portrait distance.
struct CountdownView: View {
    let remaining: Int
    let isSubjectFacing: Bool

    var body: some View {
        if isSubjectFacing {
            Text(remaining, format: .number)
                .font(.system(.largeTitle, design: .serif))
                .scaleEffect(6)
                .foregroundStyle(PeekTheme.cream)
                .shadow(color: PeekTheme.ink, radius: 8)
        } else {
            Text(remaining, format: .number)
                .font(.largeTitle)
                .bold()
                .monospacedDigit()
                .padding()
                .foregroundStyle(PeekTheme.cream)
                .background(PeekTheme.ink, in: .circle)
        }
    }
}

#Preview("Subject") {
    CountdownView(remaining: 3, isSubjectFacing: true)
}
