import SwiftUI

/// A small state label: "LIVE", "POSE REFERENCE", "SHOT 2 OF 4". The text states the condition.
struct PeekChip: View {
    let text: LocalizedStringResource
    /// The fill. On a photo it is `surface`. On the page it is `fill`.
    var background = PeekTheme.surface

    var body: some View {
        Text(text)
            .font(.caption)
            .bold()
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.vertical, PeekTheme.tightSpace)
            .foregroundStyle(PeekTheme.ink)
            .background(background, in: .rect(cornerRadius: PeekTheme.chipCorner))
    }
}

#Preview {
    VStack {
        PeekChip(text: .poseReference, background: PeekTheme.fill)
        PeekChip(text: .live)
    }
    .padding()
    .background(PeekTheme.page)
}
