import SwiftUI

/// The time remaining. The subject-facing form fills the display so it reads at portrait distance.
struct CountdownView: View {
    let remaining: Int
    let isSubjectFacing: Bool

    var body: some View {
        if isSubjectFacing {
            Image(systemName: "\(remaining).circle.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black)
                .padding()
                .accessibilityLabel(Text(remaining, format: .number))
        } else {
            Text(remaining, format: .number)
                .font(.largeTitle)
                .bold()
                .monospacedDigit()
                .padding()
                .background(.regularMaterial, in: .circle)
        }
    }
}

#Preview("Subject") {
    CountdownView(remaining: 3, isSubjectFacing: true)
}
