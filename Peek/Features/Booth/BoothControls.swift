import PeekCore
import SwiftUI

/// The photographer's controls. They stay on the inner display. Each state has one filled main action.
struct BoothControls: View {
    @Bindable var model: BoothSessionModel
    /// True at the side of a wide booth: the main action of the ready state is the round shutter.
    var usesShutter = false

    var body: some View {
        VStack(alignment: .leading) {
            if model.isDraftUnsaved {
                Text(.draftNotSaved)
            }
            switch model.state.phase {
            case .setup:
                EmptyView()
            case .ready:
                if model.state.lastFailure != nil {
                    Text(.captureFailed)
                }
                LayoutPicker(model: model)
                Picker(selection: $model.countdown) {
                    Text(.countdownManual).tag(CountdownLength.manual)
                    Text(.countdownThree).tag(CountdownLength.three)
                    Text(.countdownFive).tag(CountdownLength.five)
                } label: {
                    Text(.countdownLabel)
                }
                .pickerStyle(.segmented)
                if usesShutter {
                    ShutterButton(label: startLabel) { model.send(.start) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Button { model.send(.start) } label: { Text(startLabel) }
                        .buttonStyle(PeekPrimaryButtonStyle())
                }
            case .countdown:
                Button(role: .cancel) { model.send(.cancel) } label: { Text(.cancel) }
                    .buttonStyle(PeekSecondaryButtonStyle())
            case .capturePending:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case let .paused(_, reason):
                switch reason {
                case .outerDisplayLost:
                    // Lookbook page 07: the countdown starts again only after an explicit action.
                    Text(.countdownPaused)
                        .font(PeekFont.sans(.title3))
                    if let cue = model.currentCue {
                        Text(cue.name)
                    }
                    Button { model.send(.resume) } label: { Text(.continueOneScreen) }
                        .buttonStyle(PeekPrimaryButtonStyle())
                case .recovered:
                    Text(.draftRestored)
                    resumeButton
                case .photographer, .interruption:
                    Text(.paused)
                    resumeButton
                }
            case .review:
                let stack = usesShutter ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
                stack {
                    Button { model.send(.redo) } label: { Text(.retakeShotNumber(model.state.currentSlotID.index + 1)) }
                        .buttonStyle(PeekSecondaryButtonStyle())
                    Button { model.send(.accept) } label: { Text(.keepShot) }
                        .buttonStyle(PeekPrimaryButtonStyle())
                }
            case .complete:
                FinishedControls(model: model)
            }
        }
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.white)
    }

    /// With no countdown, the action takes the shot at once.
    private var startLabel: LocalizedStringResource {
        model.countdown == .manual ? .takeShot : .startCountdown
    }

    private var resumeButton: some View {
        Button { model.send(.resume) } label: { Text(.resume) }
            .buttonStyle(PeekPrimaryButtonStyle())
    }
}
