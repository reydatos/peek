import SwiftUI

/// The side rail of a wide booth: the pose reference above the four slots. Lookbook pages 00 and 05.
struct BoothRail: View {
    let model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            if model.isComplete {
                Text(.yourStrip)
                    .font(PeekFont.sans(.title2))
                Spacer()
            } else if let cue = model.currentCue {
                PeekChip(text: .poseReference)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                VStack(alignment: .leading) {
                    PoseArt(cue: cue)
                    Text(cue.name)
                        .font(PeekFont.sans(.headline))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer()
            }
            SlotRail(model: model, axis: .vertical)
        }
        .padding()
        .foregroundStyle(Color.white)
    }
}
