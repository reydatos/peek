import SwiftUI

/// The pose name over the photographer's viewfinder, with a button on each side to change the pose.
struct PoseStepper: View {
    let model: BoothSessionModel

    var body: some View {
        HStack {
            Button { model.stepPose(by: -1) } label: {
                Label(.previousPose, systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            Label(model.currentCue?.name ?? .samplePrompt, systemImage: "figure.wave")
            Button { model.stepPose(by: 1) } label: {
                Label(.nextPose, systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
        }
        .font(PeekFont.sans(.headline))
        .padding()
        .foregroundStyle(Color.white)
        .background(PeekTheme.ink, in: .capsule)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
}
