import SwiftUI

/// The round shutter at the side of a wide booth, clear of the fold. Lookbook pages 00 and 02.
struct ShutterButton: View {
    let label: LocalizedStringResource
    let action: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var diameter = 72
    @ScaledMetric(relativeTo: .largeTitle) private var ring = 4

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(PeekTheme.cream)
                .padding(ring * 2)
                .overlay {
                    Circle().strokeBorder(PeekTheme.cream, lineWidth: ring)
                }
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

#Preview {
    ShutterButton(label: .startCountdown) {}
        .padding()
        .background(PeekTheme.ink)
}
