import PeekCore
import SwiftUI

/// The black bar below the viewfinder on a tall display, as in a camera app.
/// It has the four progress bars and the actions of the state.
struct BoothCameraBar: View {
    let model: BoothSessionModel
    let actions: BoothActions
    @ScaledMetric(relativeTo: .body) private var thumbnail = 52

    var body: some View {
        VStack {
            ShotProgressBars(model: model)
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

    @ViewBuilder private var controls: some View {
        switch model.state.phase {
        case .setup, .complete:
            EmptyView()
        case .ready:
            HStack {
                // The flip button is directly left of the shutter (owner decision, 2026-11-15).
                HStack {
                    lastShot
                    Spacer(minLength: 0)
                    FlipCameraButton(model: model)
                }
                .frame(maxWidth: .infinity)
                shutter
                // The poses button is an icon, as on the side rail, so the shutter stays in the center.
                Button(action: actions.showPoses) {
                    PeekIconLabel(text: .poses, systemImage: "square.grid.2x2")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        }
    }

    /// The last accepted shot, or an empty frame before the first one.
    private var lastShot: some View {
        let image = model.state.slots.last { $0.acceptedTake != nil }.flatMap { model.image(for: $0) }
        return PeekTheme.fill
            .frame(width: thumbnail, height: thumbnail)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(.rect(cornerRadius: PeekTheme.smallPhotoCorner))
            .accessibilityHidden(true)
    }
}
