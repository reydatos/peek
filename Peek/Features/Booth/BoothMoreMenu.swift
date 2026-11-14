import PeekCore
import SwiftUI

/// The controls that have no place on the rail: the countdown length, the camera flip, and the outer display.
struct BoothMoreMenu: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        Menu {
            Picker(selection: $model.countdown) {
                Text(.countdownManual).tag(CountdownLength.manual)
                Text(.countdownThree).tag(CountdownLength.three)
                Text(.countdownFive).tag(CountdownLength.five)
            } label: {
                Text(.countdownLabel)
            }
            Button { Task { await model.flipCamera() } } label: {
                Label(.flipCamera, systemImage: "arrow.triangle.2.circlepath.camera")
            }
            .disabled(model.state.phase != .ready)
            if model.isOuterDisplayAvailable, !model.isSelfie {
                Toggle(isOn: $model.isOuterDisplayEnabled) {
                    Label(.showOnOuterDisplay, systemImage: "rectangle.on.rectangle")
                }
                Toggle(isOn: $model.isOuterPreviewMirrored) {
                    Label(.mirrorOuterPreview, systemImage: "arrow.left.and.right")
                }
            }
        } label: {
            PeekIconLabel(text: .more, systemImage: "ellipsis")
        }
    }
}
