import PeekCore
import SwiftUI

/// The side rail of a wide booth, on the trailing edge and clear of the fold.
/// Top to bottom: close, the pose reference, the four slots, the actions of the state, and the flip and poses buttons.
/// This is the one pose reference of the wide booth, so it also shows the move of an animated pose.
/// With one screen, the pose reference is in the photo, for the people in the photo.
struct BoothSideRail: View {
    let model: BoothSessionModel
    let actions: BoothActions
    @State private var isConfirmingNewSet = false
    @ScaledMetric(relativeTo: .body) private var thumbnailHeight = 124

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
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
                Button(action: actions.close) {
                    PeekIconLabel(text: .close, systemImage: "xmark")
                }
                Spacer()
                BoothMoreMenu(model: model)
            }
            // With one screen, the photo has the large pose reference, so the rail shows none.
            if !model.isComplete, model.isOuterDisplayPresenting, let cue = model.currentCue {
                PoseReferenceFrame(cue: cue, accent: model.accent, showsMove: true)
                    .frame(height: thumbnailHeight)
                Text(cue.name)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
            SlotRail(model: model, axis: .horizontal)
            Spacer(minLength: 0)
            stateActions
            if model.state.phase == .ready {
                Spacer(minLength: 0)
                HStack {
                    FlipCameraButton(model: model)
                    Button(action: actions.showPoses) {
                        PeekIconLabel(text: .poses, systemImage: "square.grid.2x2")
                    }
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
            ShutterButton(label: model.countdown == .manual ? .takeShot : .startCountdown) { model.send(.start) }
            Text(model.countdown == .manual ? .takeShot : .startAfterSeconds(model.countdown.seconds))
                .font(.footnote)
                .fontWeight(.semibold)
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
        SaveStatusLabel(status: model.saveStatus)
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
