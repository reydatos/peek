import PeekCore
import SwiftUI

/// The photographer's controls on a tall display. Each state has one red main action.
/// The status messages are on the photo (`BoothBanners`).
struct BoothControls: View {
    let model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            switch model.state.phase {
            case .setup:
                EmptyView()
            case .ready:
                Button { model.send(.start) } label: {
                    Text(model.countdown == .manual ? .takeShot : .startAfterSeconds(model.countdown.seconds))
                }
                .buttonStyle(PeekPrimaryButtonStyle())
                .accessibilityLabel(Text(model.countdown == .manual ? .takeShot : .startCountdown))
            case .countdown:
                Button(role: .cancel) { model.send(.cancel) } label: { Text(.cancel) }
                    .buttonStyle(PeekSecondaryButtonStyle())
            case .capturePending:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case let .paused(_, reason):
                Button { model.resume() } label: {
                    Text(reason == .outerDisplayLost && !model.isOuterDisplayAvailable ? .continueOneScreen : .resume)
                }
                .buttonStyle(PeekPrimaryButtonStyle())
            case .review:
                HStack {
                    Button { model.send(.redo) } label: {
                        Label(.retakeShotNumber(model.state.currentSlotID.index + 1), systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(PeekSecondaryButtonStyle())
                    Button { model.send(.accept) } label: {
                        Label(.keepShot, systemImage: "checkmark")
                    }
                    .buttonStyle(PeekPrimaryButtonStyle())
                }
            case .complete:
                FinishedControls(model: model)
            }
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(PeekTheme.ink)
    }
}
