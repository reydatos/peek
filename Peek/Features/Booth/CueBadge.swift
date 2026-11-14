import SwiftUI

struct CueBadge: View {
    let text: LocalizedStringResource
    let systemImage: String
    let isSubjectFacing: Bool
    /// The pose to copy. It shows beside the cue on a subject-facing display.
    var art: PoseCue?

    var body: some View {
        if isSubjectFacing {
            // An ivory card at the bottom, so it reads at portrait distance and stays below faces.
            HStack(alignment: .bottom) {
                Text(text)
                    .font(PeekFont.sans(.largeTitle))
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PeekTheme.ink)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(PeekTheme.cream, in: .rect(cornerRadius: PeekTheme.corner))
                if let art {
                    PoseArt(cue: art)
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 0)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
        } else {
            Label(text, systemImage: systemImage)
                .font(PeekFont.sans(.headline))
                .padding()
                .foregroundStyle(Color.white)
                .background(PeekTheme.ink, in: .capsule)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
        }
    }
}
