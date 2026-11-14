import SwiftUI

/// A small state label: "LIVE", "POSE REFERENCE", "SHOT 2 OF 4". The text states the condition; the color supports it.
struct PeekChip: View {
    let text: LocalizedStringResource
    var isLive = false

    var body: some View {
        Text(text)
            .font(PeekFont.sans(.caption))
            .bold()
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.vertical, PeekTheme.smallCorner)
            .foregroundStyle(PeekTheme.ink)
            .background(isLive ? PeekTheme.live : Color.white, in: .rect(cornerRadius: PeekTheme.smallCorner))
    }
}

#Preview {
    VStack {
        PeekChip(text: .poseReference)
        PeekChip(text: .live, isLive: true)
    }
    .padding()
    .background(PeekTheme.ink)
}
