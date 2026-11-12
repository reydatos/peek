import SwiftUI

/// The photographer's pane on a wide display: progress, the pose, the pose swap, the slot rail, and the controls.
struct BoothSidePane: View {
    let model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(.shot)
                Text(verbatim: "\(model.state.currentSlotID.index + 1)/\(model.state.slots.count) ·")
                if let pack = model.pack {
                    Text(pack.name)
                }
            }
            .modifier(PeekSectionLabel())
            Text(model.currentCue?.name ?? .samplePrompt)
                .font(.largeTitle)
                .fontDesign(.serif)
            // The large reference takes all the free height, so the photographer can direct the pose.
            if let cue = model.currentCue {
                PoseArt(cue: cue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer()
            }
            Text(.swapPose)
                .modifier(PeekSectionLabel())
            PoseSwapRow(model: model)
            SlotRail(model: model)
            BoothControls(model: model)
        }
        .padding()
        .foregroundStyle(PeekTheme.cream)
    }
}
