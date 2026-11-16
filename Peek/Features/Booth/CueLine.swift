import PeekCore
import SwiftUI

/// The line below the photo: the pose name with a caption, or the countdown.
struct CueLine: View {
    let model: BoothSessionModel
    /// True when the people in the photo read this display.
    let isSubjectFacing: Bool

    var body: some View {
        let number = model.state.currentSlotID.index + 1
        let count = model.state.slots.count
        ZStack(alignment: .leading) {
            // The line keeps the height of the countdown, so the photo does not change size when the countdown starts.
            // A finished set has no countdown, so it keeps no height.
            if !model.isComplete {
                CountdownView(remaining: 0, total: model.countdown.seconds, isLarge: isSubjectFacing)
                    .hidden()
            }
            switch model.state.phase {
            case let .countdown(remaining):
                CountdownView(remaining: remaining, total: model.countdown.seconds, isLarge: isSubjectFacing)
            case .ready, .paused:
                line(cueName, caption: .shotOf(number, count))
            case .capturePending:
                line(Text(.capturing), caption: .shotOf(number, count))
            case .review:
                line(cueName, caption: .shotReview(number))
            case .setup, .complete:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The name of the pose of the current shot.
    private var cueName: Text {
        model.currentCue?.name.text ?? Text(.samplePrompt)
    }

    private func line(_ name: Text, caption: LocalizedStringResource) -> some View {
        VStack(alignment: .leading) {
            name
                .font(isSubjectFacing ? .largeTitle : .title2)
                .bold()
                .foregroundStyle(PeekTheme.ink)
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(PeekTheme.inkSecondary)
        }
    }
}
