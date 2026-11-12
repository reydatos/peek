import PeekCore
import SwiftUI

/// The photographer's controls. They stay on the inner display.
struct BoothControls: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        VStack {
            switch model.state.phase {
            case .setup:
                EmptyView()
            case .ready:
                if model.state.lastFailure != nil {
                    Text(.captureFailed)
                }
                Picker(selection: $model.countdown) {
                    Text(.countdownManual).tag(CountdownLength.manual)
                    Text(.countdownThree).tag(CountdownLength.three)
                    Text(.countdownFive).tag(CountdownLength.five)
                } label: {
                    Text(.countdownLabel)
                }
                .pickerStyle(.segmented)
                Button { model.send(.start) } label: {
                    Label(.start, systemImage: "camera.shutter.button")
                }
                .buttonStyle(.borderedProminent)
            case .countdown:
                Button(role: .cancel) { model.send(.cancel) } label: {
                    Label(.cancel, systemImage: "xmark")
                }
                .buttonStyle(.bordered)
            case .capturePending:
                ProgressView()
            case let .paused(_, reason):
                Text(reason == .outerDisplayLost ? .pausedOuterDisplayLost : .paused)
                Button { model.send(.resume) } label: {
                    Label(.resume, systemImage: "play")
                }
                .buttonStyle(.borderedProminent)
            case .review:
                HStack {
                    Button { model.send(.redo) } label: {
                        Label(.redo, systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    Button { model.send(.accept) } label: {
                        Label(.accept, systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .complete:
                Button { model.send(.retake(model.state.currentSlotID)) } label: {
                    Label(.shootAgain, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}
