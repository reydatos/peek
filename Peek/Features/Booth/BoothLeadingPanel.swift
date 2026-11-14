import PeekCore
import SwiftUI

/// The leading panel of a wide booth: the pose reference with its name, its pack, and previous and next.
/// For a finished set it holds the layout choice.
struct BoothLeadingPanel: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            if model.isComplete {
                Text(.yourStrip)
                    .font(.title2)
                    .bold()
                LayoutPicker(model: model)
                FramePicker(model: model)
                Spacer()
            } else if let cue = model.currentCue {
                PeekChip(text: .poseReference, background: PeekTheme.fill)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                PoseReferenceFrame(cue: cue, accent: model.accent, cornerRadius: PeekTheme.photoCorner)
                Text(cue.name)
                    .font(.title3)
                    .bold()
                if let pack = model.pack {
                    Text(pack.name)
                        .font(.subheadline)
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
                HStack {
                    Button { model.stepPose(by: -1) } label: {
                        PeekIconLabel(text: .previousPose, systemImage: "chevron.left")
                    }
                    Button { model.stepPose(by: 1) } label: {
                        PeekIconLabel(text: .nextPose, systemImage: "chevron.right")
                    }
                }
                .disabled(model.state.phase != .ready)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(PeekTheme.ink)
        .padding()
        // The panel is narrow. Above this text size, its labels do not fit.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
