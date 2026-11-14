import SwiftUI

struct CueBadge: View {
    let text: LocalizedStringResource
    let systemImage: String
    let isSubjectFacing: Bool
    /// The pose to copy. It shows beside the cue on a subject-facing display.
    var art: PoseCue?

    var body: some View {
        if isSubjectFacing {
            // A card at the bottom, so it reads at portrait distance and stays below faces.
            HStack(alignment: .bottom) {
                Text(text)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PeekTheme.ink)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                if let art {
                    PoseArt(cue: art)
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 0)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
        } else {
            Label(text, systemImage: systemImage)
                .font(.headline)
                .padding()
                .foregroundStyle(PeekTheme.ink)
                .background(PeekTheme.surface, in: .capsule)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
        }
    }
}
