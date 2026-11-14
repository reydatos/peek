import SwiftUI

/// The round shutter at the side of a wide booth, clear of the fold: a ring in the strong color and a red core.
struct ShutterButton: View {
    let label: LocalizedStringResource
    let action: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var diameter = 78
    @ScaledMetric(relativeTo: .largeTitle) private var ring = 4

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(PeekTheme.red)
                .padding(ring * 2)
                .overlay {
                    Circle().strokeBorder(PeekTheme.strong, lineWidth: ring)
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
        .background(PeekTheme.page)
}
