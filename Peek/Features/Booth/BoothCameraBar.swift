import PeekCore
import SwiftUI

/// The black bar below the viewfinder on a tall display, as in a camera app.
/// It has the four progress bars and the actions of the state.
struct BoothCameraBar: View {
    let model: BoothSessionModel
    let actions: BoothActions

    var body: some View {
        VStack {
            ShotProgressBars(model: model)
            if model.match.canMatch {
                // The meter keeps its space in each state, so the photo does not change size between states.
                MatchMeter(score: matchScore ?? nil)
                    .opacity(matchScore == nil ? 0 : 1)
                    .accessibilityHidden(matchScore == nil)
            }
            ZStack {
                // The bar keeps the height of the shutter row, so the photo does not change size between states.
                shutter.hidden()
                controls
            }
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(model.showsInnerGlamLight ? PeekTheme.glamLight : PeekTheme.cameraChrome)
        // The bar is black in light mode too, so its content has the dark colors.
        // With the glam light, the bar is the warm light, so its content has the light-mode colors.
        .environment(\.colorScheme, model.showsInnerGlamLight ? .light : .dark)
    }

    /// The live match before the shot, and the match of the shot in review. Nil in the other states.
    private var matchScore: Double?? {
        switch model.state.phase {
        case .ready: .some(model.match.score)
        case .review: .some(model.match.reviewScore)
        default: nil
        }
    }

    @ViewBuilder private var controls: some View {
        switch model.state.phase {
        case .setup, .complete:
            EmptyView()
        case .ready:
            // The flip button, the shutter, and the poses button are one row in the center (owner decision, 2026-11-15).
            HStack {
                FlipCameraButton(model: model)
                shutter
                Button(action: actions.showPoses) {
                    PeekIconLabel(text: .poses, systemImage: "square.grid.2x2")
                }
            }
        case .countdown:
            // The numeral is on the picture, large.
            Button(role: .cancel) { model.send(.cancel) } label: {
                Label(.cancel, systemImage: "xmark")
            }
            .buttonStyle(PeekSecondaryButtonStyle())
        case .capturePending:
            ProgressView()
                .frame(minHeight: PeekTheme.touchTarget)
        case let .paused(_, reason):
            Button { model.resume() } label: {
                Label(reason == .outerDisplayLost && !model.isOuterDisplayAvailable ? .continueOneScreen : .resume, systemImage: "play")
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
        }
    }

    private var shutter: some View {
        VStack(spacing: PeekTheme.tightSpace) {
            ShutterButton(
                label: model.countdown == .manual ? .takeShot : .startCountdown,
                action: { model.send(.start) },
                ringColor: model.showsInnerGlamLight ? PeekTheme.strong : PeekTheme.paperWhite
            )
            Text(model.countdown == .manual ? .takeShot : .startAfterSeconds(model.countdown.seconds))
                .font(.footnote)
                .fontWeight(.semibold)
                // The label can be wider than the shutter, so it keeps its full width.
                .fixedSize()
        }
    }
}
