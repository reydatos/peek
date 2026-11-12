import SwiftUI

/// The photographer's pane on a wide display: progress, the prompt, the slot rail, and the controls.
struct BoothSidePane: View {
    let model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(.shot)
                Text(verbatim: "\(model.state.currentSlotID.index + 1)/\(model.state.slots.count)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(model.currentCue?.name ?? .samplePrompt)
                .font(.largeTitle)
                .bold()
            if let cue = model.currentCue {
                PoseArt(cue: cue)
                    .containerRelativeFrame(.vertical, count: 3, spacing: 0)
            }
            SlotRail(model: model)
            Spacer()
            BoothControls(model: model)
        }
        .padding()
    }
}
