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
            Text(.swapPose)
                .modifier(PeekSectionLabel())
            PoseSwapRow(model: model)
            SlotRail(model: model)
            Spacer()
            BoothControls(model: model)
        }
        .padding()
        .foregroundStyle(PeekTheme.cream)
    }
}
