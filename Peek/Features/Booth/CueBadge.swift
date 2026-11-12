import SwiftUI

struct CueBadge: View {
    let text: LocalizedStringResource
    let systemImage: String
    let isSubjectFacing: Bool

    var body: some View {
        if isSubjectFacing {
            // A cream card at the bottom, so it reads at portrait distance and stays clear of the camera housing.
            Text(text)
                .font(PeekFont.serif(.largeTitle))
                .multilineTextAlignment(.center)
                .foregroundStyle(PeekTheme.ink)
                .padding()
                .frame(maxWidth: .infinity)
                .background(PeekTheme.cream, in: .rect(cornerRadius: PeekTheme.corner))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding()
        } else {
            Label(text, systemImage: systemImage)
                .font(PeekFont.sans(.headline))
                .padding()
                .foregroundStyle(PeekTheme.cream)
                .background(PeekTheme.ink, in: .capsule)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
        }
    }
}
