import PeekCore
import SwiftUI

/// The one line on the card of the outer display picture: the countdown numeral or the shot number.
/// Live framing has no line, so the people see the full picture.
struct OuterCaption: View {
    let phase: BoothPhase
    let shotNumber: Int
    var countdownLength = 3

    var body: some View {
        Group {
            switch phase {
            case let .countdown(remaining):
                // The numeral is large, so it reads at portrait distance.
                CountdownView(remaining: remaining, total: countdownLength, isLarge: true)
            case .capturePending:
                Text(.capturing)
            case .paused:
                Text(.paused)
            case .review:
                Text(.shotNumber(shotNumber))
            case .setup, .ready, .complete:
                EmptyView()
            }
        }
        .font(.largeTitle)
        .bold()
        .multilineTextAlignment(.center)
        .foregroundStyle(PeekTheme.ink)
        .padding()
    }
}

#Preview("Countdown") {
    OuterCaption(phase: .countdown(remaining: 3), shotNumber: 2)
        .background(PeekTheme.page)
}

#Preview("Shot") {
    OuterCaption(phase: .review(.init(slotID: .init(1), token: .init(), assetName: "", rotationAngle: 0)), shotNumber: 2)
        .background(PeekTheme.page)
}
