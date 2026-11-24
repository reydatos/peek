import PeekCore
import SwiftUI

/// The side rail of a wide booth, on the trailing edge and clear of the fold.
/// Top to bottom: the More menu, the pose reference, the four slots, the actions of the state (the flip button is left of the shutter), and the poses button.
/// This is the one pose reference of the wide booth, so it also shows the move of an animated pose.
/// The rail is the same with one screen and with two, and with each camera.
struct BoothSideRail: View {
    let model: BoothSessionModel
    let actions: BoothActions
    @State private var isConfirmingNewSet = false
    @ScaledMetric(relativeTo: .body) private var thumbnailHeight = 124

    /// The space between the flip button and the shutter. This is a design value.
    private static let shutterSpace = PeekTheme.tightSpace * 4

    var body: some View {
        GeometryReader { proxy in
            // The camera housing of an open iPhone Duo is in a top corner of the rail. The rail starts below it,
            // so the housing covers no button.
            let clearance = RailClearance.top(railSize: proxy.size, occlusions: proxy.occlusions)
            ScrollView {
                content
                    .padding(.top, clearance)
                    .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // The rail has a fixed width. Above this text size, its labels do not fit.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var content: some View {
        VStack {
            HStack {
                Spacer()
                BoothMoreMenu(model: model)
            }
            if !model.isComplete, let cue = model.currentCue {
                // The pose name shows one time, on the cue line below the photo (owner decision, 2026-11-15).
                // The move shows only before the shot. The countdown and the capture then have the full power of the phone.
                // While the clip plays over the camera picture, the rail shows the still: one player is enough.
                // The arrows beside the picture change the pose. With large text, the picture is smaller so they fit.
                PoseStepper(model: model) {
                    PoseClipButton(model: model) {
                        PoseReferenceFrame(
                            cue: cue,
                            accent: model.accent,
                            showsMove: model.state.phase == .ready && model.shownClipLook == .corner
                        )
                        .frame(maxHeight: thumbnailHeight)
                    }
                }
                if model.match.canMatch, let score = model.match.meterScore {
                    MatchMeter(score: score, isTooClose: model.match.meterTooClose)
                }
            }
            SlotRail(model: model, axis: .horizontal)
            Spacer(minLength: 0)
            stateActions
            if model.state.phase == .ready {
                Spacer(minLength: 0)
                Button(action: actions.showPoses) {
                    PeekIconLabel(text: .poses, systemImage: "square.grid.2x2")
                }
            }
        }
        .foregroundStyle(PeekTheme.ink)
        .padding(PeekTheme.tightSpace * 2)
        .disabled(model.saveStatus == .saving)
    }

    @ViewBuilder private var stateActions: some View {
        switch model.state.phase {
        case .setup:
            EmptyView()
        case .ready:
            // The flip button is directly left of the shutter, as on the camera bar.
            // The space keeps a finger on the flip button clear of the shutter.
            HStack(spacing: Self.shutterSpace) {
                FlipCameraButton(model: model)
                VStack {
                    ShutterButton(label: model.countdown == .manual ? .takeShot : .startCountdown) { model.send(.start) }
                    Text(model.countdown == .manual ? .takeShot : .startAfterSeconds(model.countdown.seconds))
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
            if model.isOuterDisplayPresenting {
                let isLive = model.state.subjectView == .live
                Button { model.send(.showSubject(isLive ? .reference : .live)) } label: {
                    Label(isLive ? .showPose : .showLive, systemImage: isLive ? "figure.wave" : "video")
                }
                .buttonStyle(PeekRailButtonStyle())
            }
        case .countdown:
            Button(role: .cancel) { model.send(.cancel) } label: {
                Label(.cancel, systemImage: "xmark")
            }
            .buttonStyle(PeekRailButtonStyle())
        case .capturePending:
            ProgressView()
        case let .paused(_, reason):
            Button { model.resume() } label: {
                Label(reason == .outerDisplayLost && !model.isOuterDisplayAvailable ? .continueOneScreen : .resume, systemImage: "play")
            }
            .buttonStyle(PeekRailButtonStyle(isPrimary: true))
        case .review:
            Button { model.send(.accept) } label: {
                Label(.keepShot, systemImage: "checkmark")
            }
            .buttonStyle(PeekRailButtonStyle(isPrimary: true))
            Button { model.send(.redo) } label: {
                Label(.retakeShotNumber(model.state.currentSlotID.index + 1), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(PeekRailButtonStyle())
        case .complete:
            finishedActions
        }
    }

    @ViewBuilder private var finishedActions: some View {
        SaveStatusLabel(status: model.saveStatus, duetProgress: model.duetProgress)
        Button { Task { await model.saveStrip() } } label: {
            Label(.saveStrip, systemImage: "square.and.arrow.down")
        }
        .buttonStyle(PeekRailButtonStyle(isPrimary: true))
        if let strip = model.strip {
            ShareLink(
                item: Image(uiImage: strip),
                preview: SharePreview(Text(.yourStrip), image: Image(uiImage: strip))
            ) {
                Label(.shareStrip, systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PeekRailButtonStyle())
        }
        ChallengeShareButton(model: model, style: PeekRailButtonStyle())
        if !model.duetSegments.isEmpty {
            Button { Task { await model.makeDuet() } } label: {
                Label(.makeDuet, systemImage: "rectangle.split.1x2")
            }
            .buttonStyle(PeekRailButtonStyle())
        }
        Button { Task { await model.saveShots() } } label: {
            Label(.saveShots, systemImage: "photo.on.rectangle")
        }
        .buttonStyle(PeekRailButtonStyle())
        // A new set discards the shots, so the photographer confirms first.
        Button { isConfirmingNewSet = true } label: {
            Label(.newSet, systemImage: "plus")
        }
        .buttonStyle(PeekRailButtonStyle())
        .confirmationDialog(Text(.discardShotsTitle), isPresented: $isConfirmingNewSet, titleVisibility: .visible) {
            Button(role: .destructive) { model.startNewSet() } label: { Text(.discardShots) }
            Button(role: .cancel) {} label: { Text(.cancel) }
        } message: {
            Text(.discardShotsMessage)
        }
    }
}
