import PeekCore
import SwiftUI

/// The one line below the crop on the outer display: the cue, the countdown numeral, or the shot number.
struct OuterCaption: View {
    let phase: BoothPhase
    let cueName: LocalizedStringResource
    let shotNumber: Int

    var body: some View {
        Group {
            switch phase {
            case .ready:
                Text(cueName)
            case let .countdown(remaining):
                // The numeral is large, so it reads at portrait distance.
                Text(remaining, format: .number)
                    .monospacedDigit()
                    .scaleEffect(4)
            case .capturePending:
                Text(.capturing)
            case .paused:
                Text(.paused)
            case .review:
                Text(.shotNumber(shotNumber))
            case .setup, .complete:
                EmptyView()
            }
        }
        .font(PeekFont.sans(.largeTitle))
        .bold()
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.white)
        .padding()
    }
}

#Preview("Countdown") {
    OuterCaption(phase: .countdown(remaining: 3), cueName: .samplePrompt, shotNumber: 2)
        .background(PeekTheme.ink)
}

#Preview("Shot") {
    OuterCaption(phase: .review(.init(slotID: .init(1), token: .init(), assetName: "", rotationAngle: 0)), cueName: .samplePrompt, shotNumber: 2)
        .background(PeekTheme.ink)
}
